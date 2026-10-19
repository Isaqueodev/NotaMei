---
name: notamei-paralelo
description: Use quando desenvolver ou revisar o NotaMei. Preserve privacidade, valide Flutter e Android, separe o trabalho da main.
---

# NotaMei: trabalho verificável

Este conhecimento foi adaptado para ser portátil entre Linux e Windows. **Não use caminhos absolutos da máquina de origem.** Localize o clone do projeto no computador atual, confirme `git status --short --branch`, leia `README.md`, `pubspec.yaml` e eventuais instruções locais antes de editar. Não presuma que a branch ou o aparelho conectado sejam os mesmos da exportação. O código e a documentação versionada estão no Git; este arquivo guarda lições de trabalho, não substitui o repositório.

## Produto e privacidade

- Projeto acadêmico extensionista Android/Flutter para microempreendedores individuais. Lançamentos são manuais e persistidos em SQLite no aparelho; preferências de primeiro uso e lembretes são locais. Nesta versão não há conta, backend, sincronização própria, integração bancária ou exportação/backup próprios.
- Separe Negócio de Pessoal em cada registro. O balanço mensal do negócio é entradas menos saídas informadas, não saldo bancário. O acompanhamento anual soma somente entradas comerciais registradas, sem deduzir despesas ou inferir faturamento fiscal oficial, lucro, teto legal ou regularidade. Mês sem lançamento não prova ausência de movimento.
- O lembrete do DAS usa dia e hora escolhidos pela pessoa; nunca chame essa data de vencimento oficial ou o aviso de confirmação de pagamento. A entrega depende das permissões e da economia de bateria do Android.
- Preserve fora do Git e de serviços externos a pesquisa individual e referências visuais de terceiros. No clone original, `.gitignore` protege `docs/analise-requisitos-arquitetura.md` e `referencias de design/`; confira as regras no clone atual antes de `git add`. Não inclua credenciais, sessões, APKs ou dados de teste no commit.

## Experiência do usuário

- No primeiro uso, oferecer “Ver como funciona” ou “Começar sem tour”. Pular qualquer etapa leva ao Início; após os três passos instrutivos existe uma tela de conclusão distinta com “Pronto para começar”. É possível rever o tour em Ajustes. Não pedir permissão no tour.
- Nos testes com MEIs, use dados fictícios. Não anuncie integrações nem cálculos fiscais ainda não implementados. A instalação do APK não depende do USB após instalada; limpar dados/desinstalar pode apagar registros. Não prometa backup do Android.

## Implementação e testes

- Valores monetários são centavos inteiros; valide limites antes das somas mensais e anuais. Persistência deve preceder atualização visível. Bloqueie toque repetido enquanto salva e ofereça erro legível para nova tentativa em falha.
- Testes Flutter de widget com SQLite FFI: inicialize a factory FFI sem isolate; para I/O real disparado por toques, use `tester.runAsync` no escopo apropriado e intercale pequenas esperas reais com `pumpAndSettle`. Fechar a base em `tearDown` fora dessa zona pode travar a suíte. Confirme primeiro o teste direcionado, depois a suíte completa.
- `flutter_local_notifications` espera o nome do ícone passado a `AndroidInitializationSettings` como recurso Android válido em `drawable` (no projeto: `ic_notification`), não apenas um launcher em `mipmap`. Teste o recurso, a permissão pedida ao ativar e o agendamento/cancelamento. Se reagendamento falhar parcialmente ou permissão for revogada, cancele os alarmes próprios e não mantenha a preferência como ativa. Agendamento observado não comprova entrega futura.
- Antes de operar um dispositivo com ADB, confirme modelo e pacote. Não faça toques nem capturas se outro app estiver em primeiro plano; não limpe dados reais sem autorização. Quando houver aparelho, confira a atividade em primeiro plano antes de cada ação. Na revisão original, o Samsung A17 foi usado, mas não assuma que está conectado no Windows.
- Use `flutter analyze`, `flutter test` e `flutter build apk --debug` como validação local. Revise assinatura antes de distribuir: a configuração original de `release` usa certificado Android Debug, adequada apenas para testes controlados, não publicação. A instalação manual pode disparar avisos do Play Protect; um aviso de app desconhecido não prova vírus nem prova falso positivo. Não oriente a desativar proteção; investigue o texto exato de alertas graves.

## Trabalho paralelo e Git

- Divida escopos independentes entre agentes, preferencialmente com worktrees e branches próprios, e revise os diffs no repositório principal antes de integrar. Agentes Hermes isolados podem ver apenas HEAD, não alterações staged/untracked do checkout principal; uma revisão desses worktrees limpos **não** aprova o diff real. Faça revisão somente leitura onde o diff esteja presente e confira `git diff --cached`.
- Houve falhas com prompts relativos fora do worktree; use caminhos absolutos resolvidos no computador atual e confirme que o trabalhador leu os arquivos certos. Um teste curto de um provedor não garante que uma tarefa longa funcione; trate erros de serviço como bloqueios, sem simular resultado.
- Preserve a `main`; só comite após implementação e validação. Não faça merge/push sem autorização específica da tarefa corrente. Verifique `git status`, `git diff --check` e o histórico real antes de declarar que houve commit. Relate separadamente build local, instalação no dispositivo e entrega futura de notificações.
