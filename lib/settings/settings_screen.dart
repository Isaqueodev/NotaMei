import 'package:flutter/material.dart';
import 'package:notamei/theme/notamei_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTour,
    required this.onConfigureDas,
    required this.dasEnabled,
    this.reminderWarning,
    this.onExportCsv,
  });

  final VoidCallback? onExportCsv;
  final VoidCallback onOpenTour;
  final VoidCallback onConfigureDas;
  final bool dasEnabled;
  final String? reminderWarning;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NotaMeiTheme.paper,
    appBar: AppBar(title: const Text('Ajustes')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'CONFIGURAÇÕES LOCAIS',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: NotaMeiTheme.muted),
          ),
          const SizedBox(height: 24),
          if (reminderWarning != null) ...[
            Semantics(
              liveRegion: true,
              child: _Notice(text: reminderWarning!, isError: true),
            ),
            const SizedBox(height: 16),
          ],
          const _SectionTitle('Ações e segurança'),
          _Sheet(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.notifications_none,
                  title: 'Configurar lembrete',
                  subtitle: dasEnabled
                      ? 'Lembrete do DAS configurado'
                      : 'Lembretes desativados',
                  status: dasEnabled ? 'Ativo' : 'Desativado',
                  active: dasEnabled,
                  onTap: onConfigureDas,
                ),
                const Divider(),
                _SettingRow(
                  icon: Icons.explore_outlined,
                  title: 'Rever tour',
                  subtitle: 'Veja novamente como o NotaMei funciona',
                  onTap: onOpenTour,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Dados e avisos'),
          if (onExportCsv != null) ...[
            _Sheet(
              child: _SettingRow(
                icon: Icons.file_download_outlined,
                title: 'Exportar CSV',
                subtitle:
                    'Escolha período e filtros para salvar ou compartilhar.',
                onTap: onExportCsv,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const _Sheet(
            child: _SettingRow(
              icon: Icons.phone_android,
              title: 'Dados salvos no aparelho',
              subtitle: 'O app não oferece sincronização própria; cópias do sistema dependem das suas configurações.',
            ),
          ),
          const SizedBox(height: 12),
          const _Notice(
            text: 'Limpar os dados ou desinstalar o app pode apagar seu histórico. Não há backup próprio nem restauração pelo NotaMei nesta versão.',
          ),
          const SizedBox(height: 12),
          const _Notice(
            text: 'O NotaMei não confirma pagamento. Use os canais oficiais para verificar o DAS e seus comprovantes.',
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Sobre o NotaMei'),
          _Sheet(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/brand/notamei.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    semanticLabel: 'Marca NotaMei',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NotaMei',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Caderno de registro manual para MEI. Entradas, saídas e acompanhamento dos valores informados. Sem vínculo bancário ou validação fiscal.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: NotaMeiTheme.muted),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: NotaMeiTheme.border),
    ),
    child: child,
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.status,
    this.active = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NotaMeiTheme.ink, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                if (status != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    status!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: active ? NotaMeiTheme.income : NotaMeiTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: NotaMeiTheme.muted,
              size: 20,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: isError ? NotaMeiTheme.expense : NotaMeiTheme.ink,
          width: 2,
        ),
      ),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: isError ? NotaMeiTheme.expense : NotaMeiTheme.ink),
    ),
  );
}
