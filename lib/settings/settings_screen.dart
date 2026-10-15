import 'package:flutter/material.dart';
import 'package:notamei/theme/notamei_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTour,
    required this.onConfigureDas,
    required this.dasEnabled,
    this.reminderWarning,
  });

  final VoidCallback onOpenTour;
  final VoidCallback onConfigureDas;
  final bool dasEnabled;
  final String? reminderWarning;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (reminderWarning != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(reminderWarning!),
              ),
            ),
          const _SectionTitle('Ações e segurança'),
          _SettingCard(
            icon: Icons.notifications_none,
            title: 'Configurar lembrete',
            subtitle: dasEnabled
                ? 'Lembrete do DAS configurado'
                : 'Lembretes desativados',
            trailing: Text(
              dasEnabled ? 'Ativo' : 'Desativado',
              style: TextStyle(
                color: dasEnabled ? Colors.teal : NotaMeiTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onConfigureDas,
          ),
          _SettingCard(
            icon: Icons.school_outlined,
            title: 'Rever tour',
            subtitle: 'Veja novamente como o NotaMei funciona',
            onTap: onOpenTour,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Dados e avisos'),
          _SettingCard(
            icon: Icons.phone_android,
            title: 'Dados salvos no aparelho',
            subtitle: 'O app não oferece sincronização própria; cópias do sistema dependem das suas configurações.',
            onTap: null,
          ),
          Card(
            color: const Color(0xFFFFF8EE),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF9A5C00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O NotaMei não confirma pagamento. Use os canais oficiais para verificar o DAS e seus comprovantes.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Sobre o NotaMei'),
          _SettingCard(
            icon: Icons.info_outline,
            title: 'NotaMei',
            subtitle: 'Controle financeiro simples para MEI',
            onTap: null,
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
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: NotaMeiTheme.muted),
    ),
  );
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: NotaMeiTheme.purple),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
    ),
  );
}
