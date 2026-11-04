path = r'C:\Users\mathe\Documents\GitHub\NotaMei-clone\README.md'
with open(path, 'a', encoding='utf-8') as f:
    f.write('\n\n## Atualização de interface (cores e fonte)\n\n')
    f.write('Alterações realizadas em `feat/atualizacao-ui-cores-fontes` (commit `fedf6fb`):\n\n')
    f.write('| Arquivo | Alteração |\n')
    f.write('| --- | --- |\n')
    f.write('| `lib/theme/notamei_theme.dart` | Nova paleta centralizada: cor principal `#142D4E`, cor de destaque `#28B889`, cor de fundo `#F4F7FA`. `ColorScheme` atualizado com `primary`/`secondary`, mapeamento de tokens antigos para novos e padronização de toda a tipografia para `Roboto`. |\n')
    f.write('| `pubspec.yaml` | Substituição das fontes `Inter` e `Playfair Display` por `Roboto` (Regular 400, Medium 500, Bold 700). |\n')
    f.write('| `assets/fonts/Roboto-Regular.ttf`, `Roboto-Medium.ttf`, `Roboto-Bold.ttf` | Novas fontes locais adicionadas. |\n\n')
    f.write('O tema central continua sendo utilizado em todo o app, sem necessidade de alterações em telas individuais.\n')
