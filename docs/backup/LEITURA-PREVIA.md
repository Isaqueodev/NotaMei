# Leitura limitada e dados de prévia do backup

## Recorte implementado

`BackupInspectionService` lê um `Stream<List<int>>` ou um `File` local, valida o
conteúdo pelo codec financeiro v1 e retorna um `BackupInspection` imutável.
**Não há seletor de abertura, tela de prévia nos Ajustes ou restauração neste
incremento.** O serviço não recebe repositório, não escreve no banco nem modifica,
remove ou renomeia o arquivo de origem.

Este recorte continua o [serviço de criação](CRIACAO.md), sem alterar o
[formato financeiro v1](FORMATO-V1.md), dependências, schema ou preferências.

## Uso da API

```dart
const reader = BackupInspectionService();
final inspection = await reader.inspectFile(fileLocalEscolhido);
// Alternativa para uma origem que já fornece bytes em fluxo:
final inspectionFromStream = await reader.inspectStream(fluxoDeBytes);
```

O chamador fornece a origem. Não tratar o caminho retornado pelo plugin de
salvamento como `File` local nem converter uma URI `content://` em caminho por
concatenação. A futura integração Android precisa oferecer uma origem limitada
antes de carregar/copiar o arquivo inteiro; este incremento não chama `pickFile`
nem garante limites sobre caches criados por outros componentes.

## Limites e integridade da leitura

- `inspectFile` usa `File.openRead()`, não `readAsBytes()` nem tamanho anunciado
  como única proteção. A contagem considera os bytes realmente recebidos.
- Cada chunk é conferido **antes** de entrar no acumulador. Ao exceder 10 MiB,
  a leitura falha e cancela a assinatura; não continua consumindo a origem nem
  trunca para tentar produzir um backup aparentemente válido.
- Valores fora de 0–255 em um chunk são recusados, sem normalização módulo 256.
- O acumulador copia chunks, evitando alteração retroativa por buffers reutilizados.
  UTF-8 só é interpretado após acumular o conteúdo, inclusive quando um símbolo
  multibyte foi dividido entre eventos. Chunks vazios são aceitos.
- O resultado só é produzido após fim bem-sucedido do fluxo e validação integral
  do codec: formato, versão, campos, dinheiro, datas, IDs e pares de retirada.
  Um erro após um JSON aparentemente completo também recusa toda a inspeção.
- O limite é do conteúdo acumulado. Não limita alocações já feitas pelo produtor
  do stream, todos os objetos criados pelo parser, duração de origem travada ou
  consumo total de memória. Não é garantia universal contra entrada hostil.

## Dados da prévia

O resultado contém o `FinancialBackup` validado e sua lista imutável, quantidade
real de bytes e estes metadados calculados sem alterar ou ordenar os registros:

- `recordCount`: quantidade de linhas, incluindo cada ponta de retirada;
- `businessCount` e `personalCount`: linhas por âmbito, também incluindo as pontas;
- `regularRecordCount`: apenas registros sem vínculo de retirada;
- `withdrawalOperations`: quantidade de operações vinculadas, não a soma das pontas;
- `earliestDate` e `latestDate`: registros selecionados por ano/mês/dia civil,
  sem conversão para UTC. A representação original e o horário são mantidos;
  em empate do dia, permanece a primeira representação encontrada. São datas para
  um intervalo civil, **não** os instantes cronológicos mínimo/máximo.

No histórico vazio, as contagens são zero e as datas são nulas. Um backup vazio
não é autorização para apagar registros existentes. Data de criação é acessível
em `inspection.backup.createdAt`; notas/IDs/categorias não entram nas mensagens
de erro nem em um resumo textual automático.

A prévia não calcula saldo, não certifica somas agregadas suportadas por mês/ano,
conflitos com a base atual, autenticidade ou compatibilidade de uma futura política
de restauração. JSON continua legível, sem senha/criptografia/autenticação.

## Falhas e integração futura

`BackupInspectionException` distingue `tooLarge`, `invalid` e `read`, com mensagens
constantes, sem reter o conteúdo, caminho ou exceção original. Não existe resultado
parcial aproveitável após falha. O leitor é sem estado; uma nova leitura pode ser
feita após erro, com uma nova origem legível.

A futura confirmação/restauração deve usar o mesmo snapshot validado mostrado na
prévia, não reler silenciosamente o caminho e aplicar outro conteúdo. Ainda faltam
entrada nativa Android, interface acessível, definição explícita de substituir ou
mesclar, validação agregada de domínio e escrita transacional com recuperação.

## Verificação

```sh
flutter test --no-pub test/backup
flutter analyze --no-pub
```

Há testes de arquivo sintético real preservado, ausência de arquivo, limite exato
e excesso com cancelamento, UTF-8 fragmentado, chunks vazios/mutáveis, bytes fora
da faixa, falhas após JSON completo, erros seguros e nova tentativa. Também cobrem
contagens, vazio, datas civis/empates, versão incompatível, IDs duplicados e retirada
órfã. Testes em disco não equivalem a aceite do seletor ou restauração no Android.
