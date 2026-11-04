path = r'C:\Users\USUARIO_LOCAL\Documents\GitHub\NotaMei-clone\lib\settings\settings_screen.dart'
with open(path, encoding='utf-8') as f:
    content = f.read()

# Add imports
old = "import 'package:flutter/material.dart';\nimport 'package:notamei/theme/notamei_theme.dart';"
new = "import 'package:flutter/material.dart';\nimport 'package:notamei/theme/notamei_theme.dart';"
if old in content and 'themeMode' not in content:
    # Update constructor
    old_ctor = '''class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTour,
    required this.onConfigureDas,
    required this.dasEnabled,
    this.reminderWarning,
    this.onExportCsv,
    this.onExportPdf,
  });

  final VoidCallback? onExportCsv;
  final VoidCallback? onExportPdf;
  final VoidCallback onOpenTour;
  final VoidCallback onConfigureDas;
  final bool dasEnabled;
  final String? reminderWarning;'''
    new_ctor = '''class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTour,
    required this.onConfigureDas,
    required this.dasEnabled,
    this.reminderWarning,
    this.onExportCsv,
    this.onExportPdf,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final VoidCallback? onExportCsv;
  final VoidCallback? onExportPdf;
  final VoidCallback onOpenTour;
  final VoidCallback onConfigureDas;
  final bool dasEnabled;
  final String? reminderWarning;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;'''
    content = content.replace(old_ctor, new_ctor)

# Add theme section - look for "CONFIGURA" text
# Try to find after first section
old_section = """          const _SectionTitle('Ações e segurança'),"""
# Try different encoding variants
if old_section not in content:
    # Try to find "segurança" 
    idx = content.find('seguran')
    if idx > 0:
        # go back to find section title
        start = content.rfind('_SectionTitle', 0, idx)
        if start > 0:
            # find end of that line
            endline = content.find('\n', idx)
            # replace from start of _SectionTitle line to endline
            line_start = content.rfind('\n', 0, start) + 1
            old_section = content[line_start:endline+1]
            new_section = "          const _SectionTitle('Aparência'),\n          _Sheet(\n            child: _ThemeModeRow(\n              themeMode: themeMode,\n              onChanged: onThemeModeChanged,\n            ),\n          ),\n          const SizedBox(height: 24),\n" + old_section
            content = content.replace(old_section, new_section)
else:
    new_section = "          const _SectionTitle('Aparência'),\n          _Sheet(\n            child: _ThemeModeRow(\n              themeMode: themeMode,\n              onChanged: onThemeModeChanged,\n            ),\n          ),\n          const SizedBox(height: 24),\n" + old_section
    content = content.replace(old_section, new_section)

# Add widget class
widget = '''

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.themeMode,
    this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onChanged;

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.brightness_6_outlined, color: NotaMeiTheme.ink, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seguir sistema, claro ou escuro',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          DropdownButton<ThemeMode>(
            value: themeMode,
            onChanged: onChanged == null ? null : (value) {
              if (value != null) onChanged!(value);
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Sistema'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Claro'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Escuro'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
'''

if '_ThemeModeRow' not in content:
    content = content.rstrip() + '\n' + widget

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('done')
