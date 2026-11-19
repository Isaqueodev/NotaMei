# Criação de backup financeiro — serviço e saída nativa

## Estado

Este incremento implementa `BackupCreationService`, a captura serializada de todo o
histórico e a ligação ao seletor de salvamento já usado no aplicativo. A
[interface de criação](INTERFACE-CRIACAO.md) agora está ligada a **Ajustes → Criar backup**.
Há [importação aditiva do JSON](IMPORTACAO.md), sem substituir o histórico ou restaurar preferências; o aceite em Android continua pendente.

Não muda schema, registros, preferências, notificações, dependências ou permissões.
O formato permanece o [contrato financeiro v1](FORMATO-V1.md). JSON é texto legível,
incluindo todas as observações, sem senha, criptografia ou autenticação. CSV/PDF
continuam relatórios e não podem ser usados como backup restaurável.

## Captura consistente

`EntryRepository.snapshotForBackup()` participa da mesma fila das mutações:

- inicializa a base se necessário;
- aguarda operações enfileiradas antes da captura;
- retorna uma lista imutável dos registros publicados após persistência bem-sucedida;
- não inclui operações enfileiradas depois da captura;
- não usa filtros de mês, ano, âmbito ou tipo, nem chama `notifyListeners`.

A captura lê o snapshot publicado pelo repositório depois de sua inicialização,
não faz uma nova consulta SQL a cada chamada. Escritas externas que contornem o
repositório não estão cobertas. Uma operação anterior rejeitada não bloqueia a fila
nem faz o backup conter uma alteração que não foi persistida.

## Preparação e salvamento

```dart
final service = BackupCreationService(repository: repository);
final document = await service.prepare(); // bytes e metadados, sem abrir seletor
final outcome = await service.save();    // captura nova e abre o seletor
```

São duas operações alternativas: `save()` prepara seu próprio documento; não salva
a variável `document` do exemplo. Não há prévia de interface implementada neste
incremento, nem autorização de prometer que uma prévia futura será congelada sem
ligação explícita ao mesmo documento.

- A criação usa `snapshotForBackup()` e o codec v1; só o metadado de criação é UTC.
- `ExportDocument` guarda cópia imutável dos bytes. Seu contêiner é transporte;
  não define se o conteúdo é CSV, PDF ou backup e não restaura registros.
- Nome sugerido: `NotaMei_backup_<microssegundos-desde-epoch>.json`, sem notas,
  nomes de categorias ou identificadores de lançamentos. Timestamp não é garantia
  de unicidade; o destino continua sob controle do seletor.
- MIME `application/json`; `ExportGateway.saveDocument()` solicita o seletor com
  `localOnly: true`, sem compartilhamento automático, caminho fixo ou salvamento
  silencioso na pasta Downloads.
- Chamadas `save()` simultâneas **na mesma instância** são recusadas; o bloqueio é
  mantido até o retorno do seletor. O consumidor deve reutilizar a instância e
  desabilitar a ação durante o processo quando a interface for integrada.
- Mudanças no repositório enquanto o seletor está aberto não modificam os bytes
  enviados. Uma nova tentativa prepara um novo snapshot.
- Cancelamento retorna `ExportOutcome.cancelled`, nunca `saved`. Sucesso retorna
  `ExportOutcome.saved` somente após o retorno de salvamento do gateway.
- `BackupCreationException` distingue `busy`, `preparation` e `save`, sem reter a
  exceção original nem expor dados financeiros/caminhos na mensagem. Falha na
  leitura ou validação não abre o seletor. O bloqueio é liberado também em falhas
  e cancelamentos.

## O que a confirmação significa

`ExportOutcome.saved` significa que o plugin nativo informou a gravação concluída;
**não** significa releitura e comparação independente do documento Android,
autenticidade criptográfica, disponibilidade futura do provedor, sincronização ou
restauração exercitada. O serviço não recebe uma URI reutilizável e não deve
interpretar o caminho retornado pelo plugin como um `File` local seguro para leitura.

Uma falha do salvamento também não garante que nenhum arquivo parcial tenha sido
criado pelo provedor. Não remover nem sobrescrever destinos por inferência. A
interface de criação explica dados legíveis, cancelamento/erros e limites,
sem afirmar integridade não verificada. Confirmar o arquivo pelo seletor e exercer
sua leitura no aparelho fazem parte do aceite nativo pendente.

## Evidências automatizadas

```sh
flutter test --no-pub test/backup
flutter analyze --no-pub
```

Os testes novos usam SQLite FFI em memória. Verificam fila anterior/posterior,
histórico completo, recuperação da fila após rejeição, imutabilidade, metadados,
retiradas, parâmetros do canal nativo, operação pendente, bloqueio, cancelamento,
privacidade dos erros e nova tentativa.

Um teste do canal **simula o destino nativo**, grava de fato um JSON sintético em
arquivo temporário, relê os bytes e decodifica/compara todos os campos. Esse teste
não usa registros reais e não comprova funcionamento do seletor em um telefone.
A variável opcional `NOTAMEI_BACKUP_EVIDENCE_DIR`, somente no teste, preserva uma
cópia sintética para conferência independente; não altera o serviço de produção.

## Integração atual e pendências

- [Leitura limitada](LEITURA-PREVIA.md) integrada ao seletor Android e à [prévia/importação](IMPORTACAO.md).
- Política aprovada: adicionar sem apagar; IDs idênticos ignorados; qualquer conflito bloqueia o arquivo inteiro.
- Importação usa transação e não restaura preferências. Não existe substituição integral, senha ou sincronização.
- Ainda falta aceite dos seletores, arquivos no provedor e recursos assistivos no Android real.
