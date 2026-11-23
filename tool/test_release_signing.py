"""Integration checks for release signing. Uses disposable keys, never personal keys.

Run with Python 3 and JAVA_HOME pointing to a JDK, after Flutter dependencies
and the Android SDK are configured. Requires Gradle wrapper in android/.
"""
from contextlib import contextmanager
import hashlib
import errno
import re
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
PREFIX = 'NOTAMEI_SIGNING_'


class ReleaseSigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='notamei-signing-tests-DISPOSABLE-', dir=os.environ.get('TMPDIR'))
        cls.addClassCleanup(cls.temp.cleanup)
        cls.folder = Path(cls.temp.name)
        cls.password = secrets.token_urlsafe(32)
        java_home = os.environ.get('JAVA_HOME')
        cls.keytool = str(Path(java_home) / 'bin' / ('keytool.exe' if os.name == 'nt' else 'keytool')) if java_home else shutil.which('keytool')
        if not cls.keytool or not Path(cls.keytool).is_file():
            raise RuntimeError('A JDK/keytool is required; no tests were validated')
        cls.base_env = {k:v for k,v in os.environ.items() if not k.startswith(PREFIX)}
        # Avoid retaining signing inputs in reusable JVMs or configuration cache.
        cls.base_env['GRADLE_OPTS'] = '-Dorg.gradle.daemon=false -Dorg.gradle.configuration-cache=false -XX:-HeapDumpOnOutOfMemoryError'
        for filename, subject, dates in [
            ('fixture.p12', 'CN=NotaMei Signing Fixture', []),
            ('debug-renamed.p12', 'CN=Android Debug,O=Android,C=US', []),
            ('debug-multivalue.p12', 'C=US+CN=Android Debug,O=Android', []),
            ('expired.p12', 'CN=Disposable Expired Fixture', ['-startdate', '2000/01/01 00:00:00']),
            ('future.p12', 'CN=Disposable Future Fixture', ['-startdate', '2099/01/01 00:00:00']),
        ]:
            env = dict(cls.base_env, NOTAMEI_TEST_PASSWORD=cls.password)
            p = subprocess.run([cls.keytool, '-genkeypair', '-alias', 'fixture', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '30', *dates, '-dname', subject, '-storetype', 'PKCS12', '-keystore', str(cls.folder/filename), '-storepass:env', 'NOTAMEI_TEST_PASSWORD', '-keypass:env', 'NOTAMEI_TEST_PASSWORD', '-noprompt'], env=env, capture_output=True, timeout=60)
            if p.returncode:
                raise RuntimeError('Could not generate disposable key fixture')
        exported = subprocess.run([cls.keytool, '-exportcert', '-alias', 'fixture', '-keystore', str(cls.folder/'fixture.p12'), '-storetype', 'PKCS12', '-storepass:env', 'NOTAMEI_TEST_PASSWORD'], env=env, capture_output=True, timeout=30)
        if exported.returncode:
            raise RuntimeError('Could not export disposable public certificate')
        cls.fingerprint = hashlib.sha256(exported.stdout).hexdigest().upper()
        imported = subprocess.run([cls.keytool, '-importcert', '-alias', 'fixture', '-keystore', str(cls.folder/'certificate-only.p12'), '-storetype', 'PKCS12', '-storepass:env', 'NOTAMEI_TEST_PASSWORD', '-noprompt'], input=exported.stdout, env=env, capture_output=True, timeout=30)
        if imported.returncode:
            raise RuntimeError('Could not generate disposable certificate-only fixture')

    @classmethod
    def tearDownClass(cls):
        cls.password = ''
        cls.temp.cleanup()

    def environment(self, **changes):
        env = dict(self.base_env)
        env.update({PREFIX+'STORE_FILE':str(self.folder/'fixture.p12'), PREFIX+'STORE_PASSWORD':self.password, PREFIX+'KEY_ALIAS':'fixture', PREFIX+'KEY_PASSWORD':self.password, PREFIX+'STORE_TYPE':'PKCS12'})
        for name, value in changes.items():
            if value is None:
                env.pop(PREFIX+name, None)
            else:
                env[PREFIX+name] = value
        return env

    def gradle(self, tasks, env):
        wrapper = str(ROOT/'android'/('gradlew.bat' if os.name == 'nt' else 'gradlew'))
        command = ([os.environ.get('COMSPEC','cmd.exe'), '/d', '/c', wrapper] if os.name == 'nt' else [wrapper])
        cache_flags = ['--project-cache-dir', str(self.folder/'gradle-project-cache')]
        if '--configuration-cache' not in tasks:
            cache_flags.append('--no-configuration-cache')
        p = subprocess.run([*command, *tasks, '--console=plain', '--no-daemon', *cache_flags], cwd=ROOT/'android', env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=240)
        raw = p.stdout + p.stderr
        # Invalid blank inputs are not secrets; every normal console contains spaces.
        # Keep literal, nonblank credentials unchanged for both build and detection.
        values = {value for value in (self.password, env.get(PREFIX+'KEY_PASSWORD'), env.get(PREFIX+'STORE_PASSWORD'))
                  if value and not value.isspace()}
        leaked = any(value and value in raw for value in values)
        output = raw
        for value in values:
            if value:
                output = output.replace(value, '[REDACTED]')
        if leaked:
            self.fail('NOTAMEI_TEST_PASSWORD_LEAK: credential found in raw build output.\n' + output[-6000:])
        return p.returncode, output

    def rejected(self, env, reason):
        code, output = self.gradle([':app:validateReleaseSigning'], env)
        self.assertNotEqual(code, 0, 'Invalid signing configuration was accepted')
        self.assertIn(reason, output, output[-6000:])

    def test_multivalue_debug_cn_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'debug-multivalue.p12')), 'NOTAMEI_SIGNING_DEBUG')

    def test_cache_help_with_credentials_is_blocked(self):
        code, output = self.gradle(['help', '--configuration-cache', '--configuration-cache-problems=warn'], self.environment())
        self.assertNotEqual(code, 0, output[-6000:])
        self.assertIn('NOTAMEI_SIGNING_CACHE', output, output[-6000:])

    def test_direct_excluded_validator_is_blocked(self):
        self.assert_policy_rejection([':app:packageRelease', '-x', ':app:validateReleaseSigning'],
                                     self.environment(CERT_SHA256='00'*32), 'NOTAMEI_SIGNING_CERT')

    @contextmanager
    def owned_apks(self, variant):
        # Quarantine only these exact APKs, never delete an arbitrary old output.
        paths = [ROOT/'build/app/outputs/apk'/variant/f'app-{variant}.apk',
                 ROOT/'build/app/outputs/flutter-apk'/f'app-{variant}.apk']
        # Independent from fixture cleanup: failed restoration must retain originals.
        backup = Path(tempfile.mkdtemp(prefix='notamei-apk-recovery-', dir=os.environ.get('TMPDIR')))
        saved = []
        quarantined = False
        try:
            for index, path in enumerate(paths):
                if path.exists():
                    target = backup/str(index)
                    shutil.move(str(path), str(target))
                    saved.append((path, target))
            quarantined = True
            yield paths[0]
        finally:
            try:
                # Before quarantine completes, an unmoved path is still an original.
                if quarantined:
                    for path in paths:
                        if path.exists():
                            path.unlink()
                for path, target in saved:
                    shutil.move(str(target), str(path))
            except OSError:
                raise RuntimeError(f'APK restoration failed; backups preserved at {backup}') from None
            else:
                shutil.rmtree(backup)

    def assert_policy_rejection(self, tasks, env, reason):
        with self.owned_apks('release') as apk:
            code, output = self.gradle(tasks, env)
            self.assertNotEqual(code, 0, output[-6000:])
            self.assertIn(reason, output, output[-6000:])
            self.assertFalse(apk.exists(), 'Rejected build produced a new APK')

    def test_aggregate_excluded_validator_is_blocked(self):
        self.assert_policy_rejection([':app:assemble', '-x', ':app:validateReleaseSigning'],
                                     self.environment(CERT_SHA256='00'*32), 'NOTAMEI_SIGNING_CERT')

    def test_direct_missing_credentials_excluded_validator_is_blocked(self):
        self.assert_policy_rejection([':app:assembleRelease', '-x', ':app:validateReleaseSigning'],
                                     self.base_env, 'NOTAMEI_SIGNING_MISSING')

    def test_cache_debug_with_credentials_is_blocked(self):
        code, output = self.gradle([':app:assembleDebug', '--configuration-cache', '--configuration-cache-problems=warn'], self.environment())
        self.assertNotEqual(code, 0, output[-6000:])
        self.assertIn('NOTAMEI_SIGNING_CACHE', output, output[-6000:])

    def test_actual_release_compile_without_credentials(self):
        code, output = self.gradle([':app:compileReleaseKotlin'], self.base_env)
        self.assertEqual(code, 0, output[-6000:])
        self.assertIn(':app:compileReleaseKotlin', output)
        self.assertNotIn(':app:validateReleaseSigning', output)

    def test_actual_secret_free_debug_build(self):
        with self.owned_apks('debug') as apk:
            code, output = self.gradle([':app:assembleDebug'], self.base_env)
            self.assertEqual(code, 0, output[-6000:])
            self.assertTrue(apk.is_file(), 'No new debug APK')
            self.assertNotIn(':app:validateReleaseSigning', output)

    def test_actual_release_apk_and_cached_wrong_pin(self):
        with self.owned_apks('release') as apk:
            tasks = [':app:assembleRelease', '--build-cache']
            env = self.environment(CERT_SHA256=self.fingerprint)
            code, output = self.gradle(tasks, env)
            self.assertEqual(code, 0, output[-6000:])
            self.assertTrue(apk.is_file(), 'No new disposable-key release APK')
            sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
            if not sdk:
                self.fail('Android SDK required for apksigner proof')
            signer = Path(sdk)/'build-tools/36.0.0'/('apksigner.bat' if os.name == 'nt' else 'apksigner')
            command = ([os.environ.get('COMSPEC', 'cmd.exe'), '/d', '/c', str(signer)] if os.name == 'nt' else [str(signer)])
            verified = subprocess.run([*command, 'verify', '--verbose', '--print-certs', str(apk)],
                                      env=self.base_env, capture_output=True, text=True, timeout=60)
            self.assertEqual(verified.returncode, 0, 'Disposable APK signature verification failed')
            fingerprints = re.findall(r'certificate SHA-256 digest:\s*([0-9a-fA-F]+)', verified.stdout)
            self.assertIn(self.fingerprint.lower(), [value.lower() for value in fingerprints])
            # Establish the native artifact path is actually reusable, not just dry-run.
            code, output = self.gradle(tasks, env)
            self.assertEqual(code, 0, output[-6000:])
            self.assertRegex(output, r':app:packageRelease (?:UP-TO-DATE|FROM-CACHE)')
            previous = hashlib.sha256(apk.read_bytes()).digest()
            code, output = self.gradle([*tasks, '-x', ':app:validateReleaseSigning'],
                                       self.environment(CERT_SHA256='00'*32))
            self.assertNotEqual(code, 0, output[-6000:])
            self.assertIn('NOTAMEI_SIGNING_CERT', output, output[-6000:])
            self.assertEqual(previous, hashlib.sha256(apk.read_bytes()).digest(),
                             'Rejected cached build modified the test-owned APK')

    def test_each_required_input_missing_or_blank(self):
        for name in ('STORE_FILE', 'STORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD'):
            for value in (None, '', ' '):
                with self.subTest(name=name, blank=value is not None):
                    self.rejected(self.environment(**{name:value}), 'NOTAMEI_SIGNING_MISSING')

    def test_relative_path_is_blocked(self):
        self.rejected(self.environment(STORE_FILE='disposable-relative.p12'), 'NOTAMEI_SIGNING_FILE')

    def test_unsupported_store_type_is_blocked(self):
        self.rejected(self.environment(STORE_TYPE='unsupported'), 'NOTAMEI_SIGNING_TYPE')

    def test_empty_pin_is_blocked(self):
        self.rejected(self.environment(CERT_SHA256=''), 'NOTAMEI_SIGNING_CERT')

    def test_expired_certificate_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'expired.p12')), 'NOTAMEI_SIGNING_KEYSTORE')

    def test_future_certificate_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'future.p12')), 'NOTAMEI_SIGNING_KEYSTORE')

    def test_certificate_only_alias_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'certificate-only.p12')), 'NOTAMEI_SIGNING_ALIAS')

    def test_missing_configuration_is_blocked(self):
        self.rejected(self.base_env, 'NOTAMEI_SIGNING_MISSING')

    def test_missing_keystore_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'absent.p12')), 'NOTAMEI_SIGNING_FILE')

    def test_missing_key_password_is_blocked(self):
        self.rejected(self.environment(KEY_PASSWORD=None), 'NOTAMEI_SIGNING_MISSING')

    def test_repository_keystore_location_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(ROOT/'pubspec.yaml')), 'NOTAMEI_SIGNING_LOCATION')

    def test_wrong_store_password_is_blocked(self):
        self.rejected(self.environment(STORE_PASSWORD=secrets.token_urlsafe(32)), 'NOTAMEI_SIGNING_KEYSTORE')

    def test_wrong_key_password_is_blocked(self):
        self.rejected(self.environment(KEY_PASSWORD=secrets.token_urlsafe(32)), 'NOTAMEI_SIGNING_KEYSTORE')

    def test_unknown_alias_is_blocked(self):
        self.rejected(self.environment(KEY_ALIAS='absent'), 'NOTAMEI_SIGNING_ALIAS')

    def test_renamed_debug_certificate_is_blocked(self):
        self.rejected(self.environment(STORE_FILE=str(self.folder/'debug-renamed.p12')), 'NOTAMEI_SIGNING_DEBUG')

    def test_wrong_expected_certificate_is_blocked(self):
        self.rejected(self.environment(CERT_SHA256='00'*32), 'NOTAMEI_SIGNING_CERT')

    def test_malformed_expected_certificate_is_blocked(self):
        self.rejected(self.environment(CERT_SHA256='invalid-fingerprint'), 'NOTAMEI_SIGNING_CERT')

    def test_valid_disposable_key_is_accepted(self):
        code, output = self.gradle([':app:validateReleaseSigning'], self.environment())
        self.assertEqual(code, 0, output[-6000:])
        self.assertIn('NOTAMEI_SIGNING_OK', output)

    def test_matching_expected_certificate_is_accepted(self):
        code, output = self.gradle([':app:validateReleaseSigning'], self.environment(CERT_SHA256=self.fingerprint))
        self.assertEqual(code, 0, output[-6000:])
        self.assertIn('NOTAMEI_SIGNING_OK', output)

    def test_aggregate_assemble_contains_release_gate(self):
        code, output = self.gradle([':app:assemble', '--dry-run'], self.environment())
        self.assertEqual(code, 0, output[-6000:])
        self.assertIn(':app:validateReleaseSigning', output)

    def test_debug_assemble_does_not_require_release_gate(self):
        code, output = self.gradle([':app:assembleDebug', '--dry-run'], self.base_env)
        self.assertEqual(code, 0, output[-6000:])
        self.assertNotIn(':app:validateReleaseSigning', output)


class ArtifactRecoveryTests(unittest.TestCase):
    """Filesystem fault fixtures only: these byte samples are not valid APKs."""

    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='notamei-apk-recovery-unit-', dir=os.environ.get('TMPDIR'))
        self.addCleanup(temp.cleanup)
        self.folder = Path(temp.name)
        self.fake_root = self.folder/'fake-repository'
        self.case = ReleaseSigningTests('runTest')
        self.case.folder = self.folder/'class-fixtures'
        self.case.folder.mkdir()
        self.backup = self.folder/'independent-recovery'
        self.backup.mkdir()
        self.paths = [self.fake_root/'build/app/outputs/apk/debug/app-debug.apk',
                      self.fake_root/'build/app/outputs/flutter-apk/app-debug.apk']
        for index, path in enumerate(self.paths):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(f'DISPOSABLE ORIGINAL {index}'.encode())
        for patcher in (mock.patch.dict(globals(), {'ROOT':self.fake_root}),
                        mock.patch.object(tempfile, 'mkdtemp', return_value=str(self.backup))):
            patcher.start()
            self.addCleanup(patcher.stop)

    def assert_originals(self):
        for index, path in enumerate(self.paths):
            self.assertEqual(path.read_bytes(), f'DISPOSABLE ORIGINAL {index}'.encode())

    def test_partial_quarantine_failure_preserves_unmoved_original(self):
        move = shutil.move
        def fail_second(source, destination, *args, **kwargs):
            if Path(source) == self.paths[1]:
                raise OSError('simulated second quarantine failure')
            return move(source, destination, *args, **kwargs)
        with mock.patch.object(shutil, 'move', side_effect=fail_second):
            with self.assertRaises(OSError):
                with self.case.owned_apks('debug'):
                    self.fail('Body must not execute after failed quarantine')
        self.assert_originals()

    def test_cross_volume_quarantine_and_restore(self):
        error = OSError(errno.EXDEV, 'simulated cross-volume move')
        with mock.patch.object(os, 'rename', side_effect=error), mock.patch.object(os, 'replace', side_effect=error):
            with self.case.owned_apks('debug') as apk:
                apk.write_bytes(b'DISPOSABLE GENERATED OUTPUT')
        self.assert_originals()

    def test_restore_failure_retains_backup_outside_fixture_cleanup(self):
        move = shutil.move
        def fail_restore(source, destination, *args, **kwargs):
            if Path(source) == self.backup/'0':
                raise OSError('simulated restore failure')
            return move(source, destination, *args, **kwargs)
        with mock.patch.object(shutil, 'move', side_effect=fail_restore):
            with self.assertRaisesRegex(RuntimeError, 'backups preserved'):
                with self.case.owned_apks('debug') as apk:
                    apk.write_bytes(b'DISPOSABLE GENERATED OUTPUT')
        shutil.rmtree(self.case.folder)
        for index in range(2):
            self.assertEqual((self.backup/str(index)).read_bytes(), f'DISPOSABLE ORIGINAL {index}'.encode())


if __name__ == '__main__':
    unittest.main(verbosity=2)
