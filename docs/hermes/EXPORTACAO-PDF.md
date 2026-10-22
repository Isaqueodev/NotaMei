# NotaMei — Exportação PDF (FB05)

## Escopo e acesso

Implementada em `feature/exportacao-pdf`, sobre `c57cabe` (retirada vinculada). **Ajustes → Exportar PDF** abre a mesma tela de seleção e prévia do CSV, com ações **Salvar PDF** e **Compartilhar PDF**. CSV permanece disponível separadamente. Não há impressão direta, importação, servidor, alteração do esquema SQLite ou escrita em lançamentos.

- Data de referência e período: dia, semana de segunda a domingo, mês ou ano civil, com último dia incluído.
- Âmbito: Negócio (padrão), Pessoal ou Todos. Tipo: ambos (padrão), Entradas ou Saídas.
- Observações **desativadas por padrão**; só entram no arquivo após escolha explícita.
- A prévia e o snapshot da operação ficam congelados durante geração/saída; filtros, ações e retorno ficam bloqueados. Cancelamento, falha e sucesso são diferenciados; falha libera uma nova tentativa.
- Sem lançamentos selecionados, as duas ações ficam desabilitadas.

## Conteúdo e exatidão

PDF A4 paginado, marca N e fonte Inter locais, período/filtros/contagem, entradas, saídas, transferências enviadas/recebidas e balanço da seleção. Cada registro informa data, tipo, âmbito, valor e categoria; retiradas também mostram sua natureza e o identificador do vínculo. Observações opcionais e textos extensos são divididos em blocos que podem atravessar páginas, sem truncamento silencioso.

Seleção e cálculos são os de `CsvReport`/`ExportSelection` e `EntryTotals`, **não uma segunda implementação financeira**. Valores continuam em centavos; totais são formatados de `BigInt`, sem conversão para `double`. Em Negócio/Pessoal, a retirada afeta o balanço do âmbito. Em Todos, internas não inflacionam entradas, saídas nem balanço, mesmo com filtro de apenas um tipo; subtotais internos permanecem explícitos.

Nome: `notamei_YYYY-MM-DD_YYYY-MM-DD.pdf`. MIME: `application/pdf`. Rodapé com página/total e aviso **“Não é documento fiscal nem backup.”** Não certifica saldo bancário, completude do histórico, faturamento fiscal ou regularidade.

## Arquitetura e limites técnicos

- `lib/export/pdf_export.dart`: valida limites, carrega assets locais e renderiza com o pacote `pdf` em `Isolate.run`, fora do isolate da interface.
- `lib/export/export_document.dart`: nome/MIME e cópia imutável dos bytes.
- `lib/export/export_gateway.dart`: `saveDocument`/`shareDocument` atendem PDF; `save`/`share` conservam os contratos CSV existentes.
- `lib/export/export_screen.dart`: `ExportFormat.csv` é o padrão; a navegação PDF seleciona explicitamente `ExportFormat.pdf`.

Para limitar processamento/memória, cada PDF aceita **até 1.000 lançamentos** e **200.000 unidades UTF-16 de texto incluído** (categorias, vínculos e observações autorizadas). Ultrapassar o limite recusa a operação inteira, sem exportar um subconjunto silencioso; a mensagem orienta reduzir período, desativar observações ou usar CSV. Esses limites são técnicos, não limites financeiros ou fiscais.

A Inter empacotada cobre os textos em português exercitados, mas não todo Unicode. Símbolos sem glifo, como determinados emojis, provocam mensagem orientativa antes de entregar o arquivo, em vez de substituição silenciosa. Observações desativadas não entram nessa validação nem no limite de texto. Use CSV quando precisar preservar texto não suportado pela fonte do PDF.

## Saída, privacidade e resultados

Salvar usa o seletor Android com `localOnly: true`; compartilhar usa o Share Sheet. O app gera localmente e não faz upload automático. Compartilhamento aberto/retorno do destino **não comprova envio ou entrega**; confira no aplicativo escolhido. Cancelamento não é sucesso. Erros inesperados não expõem caminhos ou exceções técnicas na interface.

O PDF contém dados financeiros, **não tem senha/criptografia própria** e não é backup restaurável. Arquivos salvos, cópias em cache e destinos ficam fora do controle do NotaMei; não há promessa de limpeza garantida. As mesmas ressalvas de sensibilidade do [CSV](EXPORTACAO-CSV.md) se aplicam. Gerar ou falhar na exportação não altera lançamentos nem preferências.

## Verificação

- Revisão independente estática concluída sem bloqueadores; recomendações opcionais de ampliar casos de fronteira/texto e ensaiar os plugins em Android permanecem registradas fora do Git.
- `flutter analyze`: sem problemas.
- Suíte integrada: **142 testes aprovados**, incluindo navegação Ajustes→PDF, contratos de salvar/compartilhar com fronteiras nativas simuladas, MIME/nome/bytes, cancelamento, falha/retry, vazio, duplo toque e snapshot congelado em CSV/PDF.
- PDFs reais sintéticos conferidos com parser Python independente: totais/vínculo, filtros, acentos, texto literal, notas opt-in e completude de **650 lançamentos em 33 páginas**.
- APK release universal gerado e verificado: assinatura de desenvolvimento válida, pacote/API/ABIs conferidos, assets locais exatos e sem arquivos de banco/CSV privados no ZIP. É APK de teste, não distribuição definitiva.
- Cinco PDFs sintéticos renderizados e inspecionados: relatório básico, filtro Saídas, notas desativadas, nota longa em três páginas e lote de 650 registros em 33 páginas. Um verificador adicional conferiu limites dos glifos em todas as páginas e ausência de ações/anotações PDF nas amostras.
- Build avisou sobre compatibilidade futura do KGP de `flutter_file_dialog` e versões de SDK XML; não impediu a geração. Esses avisos não comprovam falha na exportação.
- **Não equivale a validação nativa em aparelho:** testes de gateway simulam plugins; salvar e compartilhar PDF no Android precisam de ensaio real.

Reprodução, na raiz, com Flutter e um ambiente Python que disponha de `pypdf`:

```sh
flutter analyze
flutter test
python test/export/verify_pdf_export.py
flutter build apk --release
```

O parser lê os PDFs sintéticos produzidos em `build/` pelos testes; eles não são dados financeiros reais e não devem ser versionados.

## Reversibilidade

Ponto de retorno: `rollback/pre-pdf-c57cabe`. As regras de negócio já pendentes antes do PDF foram preservadas separadamente em um patch externo à árvore Git. Nenhum commit/push/merge é implicado pela implementação.

Para retornar apenas o código, preserve antes todo o trabalho atual, inclusive não rastreados, por exemplo com `git stash push -u -m "wip exportacao-pdf"`; depois `git switch rollback/pre-pdf-c57cabe` e `flutter pub get`. O stash não inclui ignorados e deve ser conferido antes de mudar de branch. Não use `reset --hard`, `clean`, desinstalação ou limpeza do banco como atalho. Código continua usando esquema SQLite 2: este rollback não é downgrade de dados, restauração nem remoção de arquivos já exportados.
