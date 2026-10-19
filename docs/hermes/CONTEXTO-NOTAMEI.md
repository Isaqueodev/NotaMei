# NotaMei — continuidade no Hermes Agent (Windows)

Retrato de trabalho, **não** substitui a inspeção do clone atual. Após mudar de computador, confirme branch, histórico e testes antes de agir. Não transporte caminhos absolutos do Linux.

## Estado conhecido antes desta migração

- Repositório: NotaMei. Branch de funcionalidade `feature/notamei-mvp`, separada da `main`. Commits do MVP: `aa5b359` (aplicativo) e `c3b26e2` (README). Consulte `git status --short --branch` e `git log -3` no Windows: o histórico pode ter avançado.
- `README.md` explica o produto e seus limites. A [síntese compartilhável de requisitos e arquitetura](REQUISITOS-ARQUITETURA.md) distingue funcionalidades implementadas, validações e decisões pendentes sem publicar dados individuais. O Android é implementado em Flutter/Dart com SQLite para lançamentos, preferências locais e notificações locais. Funcionalidades: tour opcional, entradas/saídas manuais separadas entre negócio/pessoal, painel e histórico mensais, soma anual descritiva de entradas comerciais informadas e lembrete pessoal para conferir o DAS.
- Última validação do código: `flutter analyze` e 57 testes passaram. O APK **debug** foi instalado no Samsung A17 e foram observados os fluxos de tour, criação/edição/exclusão, persistência após reabrir, histórico e agendamento/cancelamento dos alarmes. Não foi observada a entrega de uma notificação futura.
- Foi gerado um APK release para testes privados (versão `1.0.0`, Android mínimo API 24), mas sua configuração usa **assinatura Android Debug**. Não foi instalado fisicamente após esse build porque o aparelho não estava conectado. Não é artefato de publicação em loja. Uma captura exibiu aviso Play Protect de desenvolvedor desconhecido; isso não demonstra malware nem comprova falso positivo. Não oriente outras pessoas a desativar a proteção.
- Sem backend, integração bancária, apuração fiscal oficial, backup/exportação ou sincronização próprios. Não chamar o balanço de saldo bancário, a soma anual de avaliação fiscal nem o lembrete de vencimento legal/pagamento confirmado.

## Questões abertas

- Aprimorar assinatura de distribuição, política de versão/atualização e teste em aparelhos reais antes de ampliar o grupo de testes.
- Definir exportação e recuperação de dados antes do uso com informações importantes.
- Definir regras de domínio fiscal com fonte apropriada; não inventar limites ou vencimentos.
- Recolher feedback dos testes privados e reproduzir problemas antes de corrigir. Se o Play Protect exibir alerta grave, investigar o texto exato antes de orientar instalação.

## Privacidade da migração

O Git compartilha apenas arquivos rastreados. A análise detalhada local `docs/analise-requisitos-arquitetura.md`, referências de design em `referencias de design/`, artefatos `build/`, arquivos locais do Android e estado/credenciais do Hermes são mantidos fora do versionamento por `.gitignore`. Verifique `git status` e `git check-ignore -v` antes de todo commit. Este documento contém síntese de trabalho, não entrevistas nem sessões da conversa.
