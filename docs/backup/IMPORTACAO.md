# Importação aditiva de backup financeiro

## Política aprovada e disponível

**Ajustes → Importar backup** adiciona os registros do JSON financeiro v1 sem apagar
ou sobrescrever os existentes. A política foi escolhida explicitamente pelo responsável:

- mesmo ID e os oito campos idênticos: ignorar, sem duplicação;
- mesmo ID com qualquer conteúdo diferente: bloquear **todo o arquivo**;
- ID novo: adicionar somente após prévia e confirmação;
- backup vazio ou composto apenas por idênticos: informar ausência de novos registros,
  sem ação de gravação na interface;
- configurações, tour, tema e lembretes permanecem inalterados.

Não há substituição integral, resolução automática de conflitos, importação de CSV/PDF,
recuperação por conta, sincronização ou senha. JSON continua legível e sem autenticação.
Validade estrutural não certifica origem ou ausência de adulteração.

IDs diferentes são registros diferentes mesmo quando valor/data/categoria coincidem;
não existe deduplicação por semelhança. Um registro excluído localmente, mas presente
no backup, poderá ser adicionado novamente. Não há tombstones de exclusão.

## Fluxo e fronteira Android

1. Escolher arquivo no seletor local Android, por `ACTION_OPEN_DOCUMENT` e
   `CATEGORY_OPENABLE`, sem novas permissões amplas de armazenamento.
2. `MainActivity` abre a URI com `ContentResolver.openInputStream`; não converte
   `content://` em caminho de arquivo nem copia o conteúdo inteiro para cache.
3. `BackupInputReader` lê em thread de trabalho, limita a **10 MiB antes de acumular**,
   encerra no máximo no primeiro byte excedente e fecha o stream em sucesso/falha.
   O limite é sobre conteúdo, não sobre todas as alocações/cópias do processo.
4. `BackupFilePicker` recebe bytes limitados no canal `br.edu.notamei/backup`, método
   `pickBackup`, e usa `BackupInspectionService`/codec para validar todo o conteúdo.
   Cancelamento retorna ausência de seleção; falha nunca é resultado parcial.
5. A prévia mostra contagens por âmbito, operações de retirada, intervalo de datas
   civis, novos, idênticos e conflitos. Não mostra notas/IDs em mensagens de erro.
6. A pessoa confere a prévia, marca ciência e aciona **Confirmar e importar**.
   Qualquer conflito ou ausência de novos registros desabilita a importação.
7. Só após commit o repositório publica o novo snapshot e notifica a interface.
   A conclusão informa linhas adicionadas/ignoradas, não operações bancárias.

A tela bloqueia duplo toque, ações e retorno enquanto há operação pendente. A seleção
nova limpa a prévia anterior; cancelamento/erro não reutilizam consentimento antigo.
Não há gravação por mera seleção de arquivo. A origem é lida uma vez; a confirmação
usa o mesmo conteúdo validado da prévia, sem reler outra versão do arquivo.
Provedores de arquivos ainda podem atrasar/bloquear I/O; não há garantia de tempo máximo
ou de disponibilidade do provedor. O contrato nativo precisa de aceite em aparelho.

## Consistência e transação

`EntryRepository.previewBackupImport` participa da fila de mutações e consulta SQLite.
`BackupImportPlan` congela o histórico usado na prévia e as adições; compara ID, tipo,
âmbito, centavos, categoria, representação ISO da data, nota e vínculo da retirada.
`null`/texto vazio e data local/UTC não são normalizados como se fossem idênticos.

Na confirmação, `EntryRepository.importBackup` entra na mesma fila e em transação:

- relê a base dentro da transação e compara com o histórico da prévia;
- qualquer alteração exige nova seleção/consentimento, sem importação parcial;
- revalida o plano, o histórico existente e o combinado;
- insere somente adições, com parâmetros SQL, sem `replace`, exclusão ou alteração de schema;
- relê o snapshot antes do commit; uma falha de inserção/releitura reverte a transação;
- publica/notifica somente depois do commit. Sem adições, não há notificação financeira.

Os registros combinados devem respeitar os limites do formato: **10.000 linhas e
10 MiB serializados**, contando cada ponta de retirada. Pares completos, IDs,
centavos e representação civil original são preservados. O histórico existente
inválido não é reparado por inferência do arquivo.

Totais mensais de Todos/Negócio/Pessoal e entradas comerciais anuais são conferidos
com os cálculos existentes e centavos exatos, sem `double`. O cálculo anual de despesas
continua com seu contrato de indisponibilidade em overflow; não foi redefinido aqui.
A continuidade histórica continua com seu comportamento próprio de limites.

Conflito, prévia desatualizada, limites e erro de armazenamento têm mensagens seguras.
Não se retêm exceções SQLite, notas, IDs ou caminhos privados nessas exceções públicas.

## Validação e evidências

Testes usam **dados sintéticos**, SQLite FFI em memória/arquivo temporário e canal
simulado. Incluem preservação de campos e preferências, reimportação idempotente,
limites combinados, alteração após a prévia, concorrência na fila e rollback provocado
na segunda ponta de retirada, seguido de releitura e reabertura da base.

A interface é exercitada em **390 × 844, texto 2x, temas claro e escuro**, incluindo
conflitos, somente idênticos, cancelamento, erro, ciência obrigatória e operação pendente.
Isso não equivale a TalkBack ou seletor real de Android.

```sh
flutter test --no-pub test/backup
flutter analyze --no-pub
flutter build apk --debug --no-pub
```

O leitor Java puro também tem regressões executáveis com JDK 17, sem Android ou arquivos reais:

```sh
javac -d <pasta-de-classes-fora-do-repo> android/app/src/main/java/br/edu/notamei/notamei/BackupInputReader.java android/app/src/test/java/br/edu/notamei/notamei/BackupInputReaderTest.java
java -cp <pasta-de-classes-fora-do-repo> br.edu.notamei.notamei.BackupInputReaderTest
```

## Aceite Android ainda necessário

- Escolher JSON salvo pelo próprio app, cancelar, abrir arquivo inválido e excedente.
- Importar dados fictícios de outra base e repetir sem duplicação.
- Confirmar conflitos sem escrita parcial e testar retorno/reabertura do processo.
- Conferir funcionamento com provedores locais, permissões temporárias e TalkBack.
- Preservar dados reais: não limpar, desinstalar ou usar SQL sobre o banco do usuário.

Compilação e testes automatizados não certificam o seletor no telefone. Nenhum APK
instalado ou arquivo de Downloads é atualizado silenciosamente por esse incremento.
