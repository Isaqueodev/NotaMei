import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.cert.X509Certificate
import javax.naming.ldap.LdapName
import javax.inject.Inject
import org.gradle.api.configuration.BuildFeatures

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Passwords are process-scoped inputs, never Gradle properties or source files.
abstract class SigningBuildFeatures @Inject constructor(val features: BuildFeatures)
val signingBuildFeatures = objects.newInstance(SigningBuildFeatures::class.java).features
// Check presence (including blank values), before reading passwords into the signing model.
if ((providers.environmentVariable("NOTAMEI_SIGNING_STORE_PASSWORD").isPresent ||
        providers.environmentVariable("NOTAMEI_SIGNING_KEY_PASSWORD").isPresent) &&
    signingBuildFeatures.configurationCache.active.get()) {
    throw GradleException("NOTAMEI_SIGNING_CACHE: credentials require configuration cache to be disabled.")
}
val releaseStorePath = providers.environmentVariable("NOTAMEI_SIGNING_STORE_FILE").orNull
val releaseStorePassword = providers.environmentVariable("NOTAMEI_SIGNING_STORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("NOTAMEI_SIGNING_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("NOTAMEI_SIGNING_KEY_PASSWORD").orNull
val releaseStoreType = providers.environmentVariable("NOTAMEI_SIGNING_STORE_TYPE").getOrElse("PKCS12")
val releaseCertificatePin = providers.environmentVariable("NOTAMEI_SIGNING_CERT_SHA256").orNull

val checkReleaseSigning: () -> Unit = {
        val required = mapOf(
            "NOTAMEI_SIGNING_STORE_FILE" to releaseStorePath,
            "NOTAMEI_SIGNING_STORE_PASSWORD" to releaseStorePassword,
            "NOTAMEI_SIGNING_KEY_ALIAS" to releaseKeyAlias,
            "NOTAMEI_SIGNING_KEY_PASSWORD" to releaseKeyPassword,
        )
        val missing = required.filterValues { it.isNullOrBlank() }.keys
        if (missing.isNotEmpty()) {
            throw GradleException("NOTAMEI_SIGNING_MISSING: set ${missing.joinToString()}. See docs/entrega/ASSINATURA-ANDROID.md.")
        }
        if (!setOf("PKCS12", "JKS").any { it.equals(releaseStoreType, ignoreCase = true) }) {
            throw GradleException("NOTAMEI_SIGNING_TYPE: use PKCS12 or JKS.")
        }

        val storePassword = releaseStorePassword!!.toCharArray()
        val keyPassword = releaseKeyPassword!!.toCharArray()
        try {
            val store = File(releaseStorePath!!)
            if (!store.isAbsolute || !store.isFile) {
                throw GradleException("NOTAMEI_SIGNING_FILE: provide an existing absolute keystore path.")
            }
            val repository = rootProject.projectDir.parentFile.canonicalFile.toPath()
            if (store.canonicalFile.toPath().startsWith(repository)) {
                throw GradleException("NOTAMEI_SIGNING_LOCATION: keep the private keystore outside the repository.")
            }
            val keystore = KeyStore.getInstance(releaseStoreType)
            store.inputStream().use { keystore.load(it, storePassword) }
            if (!keystore.isKeyEntry(releaseKeyAlias)) {
                throw GradleException("NOTAMEI_SIGNING_ALIAS: the alias must identify a private key.")
            }
            if (keystore.getKey(releaseKeyAlias, keyPassword) !is PrivateKey) {
                throw GradleException("NOTAMEI_SIGNING_ALIAS: the alias must identify a private key.")
            }
            val certificate = keystore.getCertificate(releaseKeyAlias) as? X509Certificate
                ?: throw GradleException("NOTAMEI_SIGNING_CERT: an X.509 signing certificate is required.")
            certificate.checkValidity()
            val isDebug = LdapName(certificate.subjectX500Principal.name).rdns.any { rdn ->
                val attributes = rdn.toAttributes().all
                var debug = false
                while (attributes.hasMore()) {
                    val attribute = attributes.next()
                    if (attribute.id.equals("CN", ignoreCase = true)) {
                        val values = attribute.all
                        while (values.hasMore()) {
                            if (values.next().toString().equals("Android Debug", ignoreCase = true)) debug = true
                        }
                    }
                }
                debug
            }
            if (isDebug) {
                throw GradleException("NOTAMEI_SIGNING_DEBUG: a debug certificate cannot sign a release.")
            }
            if (releaseCertificatePin != null) {
                val fingerprint = MessageDigest.getInstance("SHA-256")
                    .digest(certificate.encoded).joinToString("") { "%02X".format(it) }
                if (!releaseCertificatePin.matches(Regex("[0-9a-fA-F]{64}")) ||
                    !releaseCertificatePin.equals(fingerprint, ignoreCase = true)) {
                    throw GradleException("NOTAMEI_SIGNING_CERT: the expected certificate does not match.")
                }
            }
        } catch (failure: GradleException) {
            throw failure
        } catch (_: Exception) {
            // Do not attach native exceptions: they can disclose local input values.
            throw GradleException("NOTAMEI_SIGNING_KEYSTORE: cannot unlock a valid signing key; check credentials and certificate.")
        } finally {
            storePassword.fill('\u0000')
            keyPassword.fill('\u0000')
        }
        logger.lifecycle("NOTAMEI_SIGNING_OK: release signing inputs validated.")
}

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    group = "verification"
    description = "Validates ephemeral release signing inputs without printing their values."
    notCompatibleWithConfigurationCache("Release signing uses ephemeral credentials.")
    doLast { checkReleaseSigning() }
}

// Public variant API; exact task names, never a substring match on Release.
val releaseArtifactTasks = mutableSetOf<String>()
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        val suffix = variant.name.replaceFirstChar { it.uppercaseChar() }
        releaseArtifactTasks.addAll(listOf(
            "assemble$suffix", "bundle$suffix", "package$suffix", "package${suffix}Bundle",
            "sign${suffix}Bundle", "validateSigning$suffix", "copyFlutterApk$suffix",
            "package${suffix}UniversalApk", "package${suffix}BundleApks",
        ))
    }
}
tasks.configureEach {
    if (name in releaseArtifactTasks) {
        dependsOn(validateReleaseSigning)
        // onlyIf runs even for UP-TO-DATE/FROM-CACHE tasks. Invalid policy throws;
        // it must never turn a release artifact into a silently skipped task.
        onlyIf("release signing policy") { checkReleaseSigning(); true }
    }
}
// Validate before any selected artifact path executes, even with -x on the
// standalone validator or native validation task, and before cached outputs.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name in releaseArtifactTasks }) {
        checkReleaseSigning()
    }
}

android {
    namespace = "br.edu.notamei.notamei"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.edu.notamei.notamei"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseStorePath?.takeIf { it.isNotBlank() }?.let { File(it) }
            storeType = releaseStoreType
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
