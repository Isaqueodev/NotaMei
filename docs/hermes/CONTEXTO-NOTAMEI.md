# NotaMei — contexto histórico e estado atual

Este arquivo conserva um retrato de migração para Windows e deve ser lido como **histórico**, não como fonte de verdade do checkout. Confirme branch, histórico, código e testes antes de agir. Não transporte caminhos absolutos do Linux.

## Estado atual verificado nesta T04

O código atual usa SQLite **versão 2**. A migração v1→v2 é aditiva e acrescenta `entries.withdrawal_id TEXT`; não reclassifica registros antigos, não altera preferências e não implementa downgrade. `EntryRepository` serializa `upsert`, `remove` e `saveWithdrawal` em uma fila e executa cada mutação em transação; só publica o snapshot e notifica após a transação concluir. `saveWithdrawal` grava, atualiza ou remove o par Negócio → Pessoal com o mesmo identificador de operação, e o formulário comum não desmembra uma retirada.

O app atual também implementa FB04/FB05: seleção/prévia comum por período, âmbito, tipo e observações opt-in; `CsvReport`/`EntryTotals`; gerador CSV; gerador PDF em isolate; `ExportDocument`; e gateway nativo para salvar ou compartilhar. Os relatórios não alteram o banco e não são backup restaurável. Esses fatos devem prevalecer sobre as notas históricas abaixo.

## Estado conhecido antes desta migração

- Repositório: NotaMei. Branch de funcionalidade `feature/notamei-mvp`, separada da `main`. Commits do MVP: `aa5b359` (aplicativo) e `c3b26e2` (README). Consulte `git status --short --branch` e `git log -3` no Windows: o histórico pode ter avançado.
- `README.md` explica o produto e seus limites. A [síntese compartilhável de requisitos e arquitetura](REQUISITOS-ARQUITETURA.md) distingue funcionalidades implementadas, validações e decisões pendentes sem publicar dados individuais. O Android é implementado em Flutter/Dart com SQLite para lançamentos, preferências locais e notificações locais. Funcionalidades: tour opcional, entradas/saídas manuais separadas entre negócio/pessoal, painel e histórico mensais, soma anual descritiva de entradas comerciais informadas e lembrete pessoal para conferir o DAS.
- Última validação do código: `flutter analyze` e 57 testes passaram. O APK **debug** foi instalado no Samsung A17 e foram observados os fluxos de tour, criação/edição/exclusão, persistência após reabrir, histórico e agendamento/cancelamento dos alarmes. Não foi observada a entrega de uma notificação futura.
- Foi gerado um APK release para testes privados (versão `1.0.0`, Android mínimo API 24), mas sua configuração usa **assinatura Android Debug**. Não foi instalado fisicamente após esse build porque o aparelho não estava conectado. Não é artefato de publicação em loja. Uma captura exibiu aviso Play Protect de desenvolvedor desconhecido; isso não demonstra malware nem comprova falso positivo. Não oriente outras pessoas a desativar a proteção.
- Sem backend, integração bancária, apuração fiscal oficial, backup/restauração ou sincronização próprios. CSV/PDF existem como relatórios de saída, mas não são backup restaurável. Não chamar o balanço de saldo bancário, a soma anual de avaliação fiscal nem o lembrete de vencimento legal/pagamento confirmado.

As contagens e observações de validação listadas abaixo pertencem às evoluções históricas documentadas; não foram reexecutadas por esta atualização documental.

## Questões abertas

- Aprimorar assinatura de distribuição, política de versão/atualização e teste em aparelhos reais antes de ampliar o grupo de testes.
- Definir exportação e recuperação de dados antes do uso com informações importantes.
- Definir regras de domínio fiscal com fonte apropriada; não inventar limites ou vencimentos.
- Recolher feedback dos testes privados e reproduzir problemas antes de corrigir. Se o Play Protect exibir alerta grave, investigar o texto exato antes de orientar instalação.

## Privacidade da migração

O Git compartilha apenas arquivos rastreados. A análise detalhada local `docs/analise-requisitos-arquitetura.md`, referências de design em `referencias de design/`, artefatos `build/`, arquivos locais do Android e estado/credenciais do Hermes são mantidos fora do versionamento por `.gitignore`. Verifique `git status` e `git check-ignore -v` antes de todo commit. Este documento contém síntese de trabalho, não entrevistas nem sessões da conversa.
