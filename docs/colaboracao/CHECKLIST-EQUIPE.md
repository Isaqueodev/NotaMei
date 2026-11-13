# Checklist proposto da equipe NotaMei

**Reconciliação documental de 12/11/2026:** base `0cacabc`, após as PRs #25 (T10), #26 (textos) e #27 (continuidade). Bases históricas do checklist: `a3e3764` e `da4b2a4`. **Proprietário e integrador:** Pedro Isaque. Responsáveis preservados; Raphael Max trabalha com Windows e iPhone, sem exigência de Android. Marcações abaixo distinguem entrega original de validação posterior. Este documento não comprova trabalho local em andamento nem disponibilidade atual. Ver [estado, evidências e coordenação](ESTADO-E-COORDENACAO.md).

Contexto: [diagnóstico e limites da auditoria](DIAGNOSTICO-REPOSITORIO.md), [benchmark](BENCHMARK-FUNCIONALIDADES.md), [guia para IAs](GUIA-IA-EQUIPE.md) e [contrato de tarefa](TAREFA-PARA-IA.md). CSV/PDF e retirada já existem: a tarefa é validar/preservar, não recriar.

**Insumo e evolução:** [feedback de 04/11/2026](../avaliacao/FEEDBACK-MEI-2026-11-04.md), de uma pessoa em dois instrumentos, e [backlog correspondente](../avaliacao/BACKLOG-MELHORIAS.md). T10/MEL-MEI-02 já foi integrada pela PR #25; MEL-MEI-01 foi integrada pela PR #27 no recorte sem saldo inicial manual. Isso não autoriza os demais itens do backlog nem comprova validação Android.

## Pedro Isaque — decisões e integração

- [ ] Confirmar prioridades, disponibilidade e a divisão abaixo com os três.
- [ ] Escolher candidato de versão e ambiente para os testes; autorizar separadamente operação de aparelho e fixtures.
- [ ] Decidir política de falha do refresh DAS e alcance das datas antes de mudanças de regra.
- [ ] Manter custódia das chaves/assinatura e aprovar eventual mudança de versão/distribuição.
- [ ] Revisar diffs e evidências, resolver arquivos compartilhados e decidir commits/merge/publicação. O Hermes não é requisito para a contribuição dos demais.
- [ ] Confirmar com orientação o que conta como IA/API e quais evidências acadêmicas são exigidas.

### Tarefas retiradas da execução de Raphael

- [ ] **T02 — política e falha parcial do refresh DAS (prioridade 1; médio).** Pedro coordena a decisão e a designação de um executor; não há substituto presumido. Mantém o escopo de `lib/das/das_reminder_service.dart` e testes do serviço, com política definida antes de alterar código. **Aceite preservado:** erro no meio da janela, retry, preferência final e falha de cancelamento; acesso aos lançamentos não bloqueado; não prometer entrega de notificação. Testes automatizados e observação Android devem ser registrados separadamente. Informar a política para T04. **Revisão:** Matheus. Pendente, não concluída por esta redistribuição.
- [ ] **T05 — matriz Android da versão exata (prioridade 0; médio).** Pedro coordena e designa alguém com aparelho Android ou ambiente Android adequado; Raphael não é responsável pela execução nativa. Documento proposto: `docs/validacao/MATRIZ-ANDROID.md`. **Aceite preservado:** commit/artefato/aparelho/API; cadastro, edição, exclusão, cancelamento e reabertura; retirada/filtros; CSV/PDF, cancelamento e compartilhamento; modo avião/permissões; agendamento versus entrega observada. Migração v1→v2 somente com base sintética dedicada. Incluir T10 e continuidade entre meses já integradas. Candidato de teste registrado: `0cacabc`, 1.0.0/build 3; build não é ensaio nativo. Itens não executados permanecem pendentes; emulador não comprova entrega em aparelho físico. **Revisão:** Pedro.

## Matheus Rebelo — proposta de foco em inicialização e entrega

Skill principal: [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md).

- [x] **T01 — inicialização recuperável (prioridade 1; esforço médio).** Implementação integrada pelas PRs #10/#11, com `StartupScreen` e teste próprio em `test/app/`; sem nova alteração de repositório/banco nesta reconciliação. **Aceite original:** falha injetada exibe orientação; retry abre os registros; não recria/limpa base; falha de lembrete continua não bloqueante. Os 2 testes específicos passaram na auditoria de `0cacabc`; isso não comprova todos os tipos de falha real ou ensaio Android, que permanece em T05. Não recriar a funcionalidade. **Revisão cruzada:** Raphael, sem atribuir a ele operação Android.
- [x] **T06 — plano de versão e atualização (prioridade 1; médio).** Plano documental entregue pela PR #14 em `docs/entrega/VERSAO-E-ATUALIZACAO.md`; cenário fictício preservado, com registro complementar do candidato atual. Esta marcação não declara ensaio de atualização executado nem preservação de registros/preferências comprovada: isso depende de T05. Qualquer alteração em Gradle/pubspec ou chaves depende de Pedro. Não publicar. **Revisão:** Pedro.
- [ ] **T09 — roteiro reproduzível de demonstração (prioridade 0; pequeno).** `docs/entrega/ROTEIRO-DEMONSTRACAO.md` existe, mas está vazio na base auditada; tarefa não entregue. Preparar rascunho com dados fictícios e incorporar os resultados reais de T05 quando disponíveis, sem inventar execução. **Aceite:** mostrar tour, sequência, filtros, retirada, anual, continuidade, CSV/PDF e reabertura; ter contingência para falha de arquivo/lembrete; não chamar balanço de saldo/lucro nem agendamento de entrega. **Revisão:** Luchie.
- [ ] Depois das prioridades e de aprovação, assumir **H01 — busca textual no Histórico** do benchmark, sem sobrepor alterações de outra pessoa no mesmo arquivo.

## Raphael Max — desenvolvimento e testes sem depender de Android

**Ambiente informado por Pedro:** computador **Windows** e celular **iPhone**; não presumir acesso a Mac, Android, emulador ou SDK já instalado.

Skill principal: [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md). Para T07, usar também [documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md). A entrega de T10 é código Dart/Flutter e testes unitários/de widget no Windows, com Flutter configurado; não exige executar o aplicativo completo como versão Windows, web ou iOS. O iPhone não substitui a validação Android. Não atribuir a Raphael instalação de APK no iPhone, build iOS local no Windows, notificações, TalkBack ou compartilhamento nativo; Android permanece com o executor de T05. Emulador Android no Windows seria uma alternativa futura, não pré-requisito nem ambiente já confirmado.

- [x] **T10 — despesas no acompanhamento anual (prioridade 1; médio).** Responsável pela implementação: **Raphael Max**. Origem: **MEL-MEI-02**. Código e testes integrados pela PR #25, commit `400d126`: entradas e despesas externas do **Negócio**, por mês e no total do ano, excluindo Pessoal/retiradas e preservando histórico parcial, ano e APIs. Os 12 testes de `test/annual/` passaram na auditoria de integração em `0cacabc`; isso não representa execução no computador de Raphael. **Escopo, evidências e limites:** [contrato T10](T10-DESPESAS-ANUAIS.md). Não reimplementar. **Revisão:** Matheus/Pedro; **validação Android pendente:** T05, coordenada por Pedro, separada desta marcação.
- [ ] **T07 — privacidade e procedência (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/entrega/PRIVACIDADE-E-RECURSOS.md`. **Aceite:** mapear dados locais/arquivos/cache/destinos; explicar que notas desligadas não anonimizam; registrar MIT/OFL e confirmar origem da marca com Pedro; não prometer limpeza/backup Android. Sem alterar Manifest por inferência. **Revisão:** Luchie/Pedro.
- [ ] Apoiar revisão de código e testes automatizados das melhorias escolhidas; filtros e retiradas não podem regredir. Na revisão de T01/T03, distinguir evidência automatizada de ensaio nativo feito por outro integrante; não assumir execução de TalkBack ou testes físicos Android.

## Luchie Bonates — proposta de foco em acessibilidade e documentação

Skill principal: [documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md). A divisão não impede sua participação em código/testes.

- [ ] **T03 — rótulos, foco e acessibilidade (prioridade 1; pequeno/médio).** **Diagnóstico inicial entregue** pela PR #18 e reconhecido na #20; o [relatório](../AVALIACAO-ACESSIBILIDADE-T03.md) e a descrição da #20 mantêm verificações pendentes. A marcação foi reconciliada com o aceite, sem apagar essa contribuição. O cenário de sequência em 390 px/texto 2x continua não aprovado na auditoria de `0cacabc`. **Aceite ainda a comprovar:** TalkBack identifica valor/observação; erros/foco são compreensíveis; texto ampliado/teclado permitem salvar/cancelar. Investigar antes de corrigir, preservar sequência/regras e coordenar ensaio Android com o executor de T05, sem presumir aparelho de Luchie. **Revisão automatizada/código:** Raphael; não é atribuição de TalkBack ao iPhone.
- [x] **T04 — atualizar arquitetura e histórico (prioridade 1; médio).** Entrega original integrada pelas PRs #22/#24 e complementada documentalmente pela #23. Preservar autoria e os arquivos combinados: `docs/arquitetura/C4-NOTAMEI.md`, `c4-notamei.html`, `docs/hermes/CONTEXTO-NOTAMEI.md` e `EXPORTACAO-CSV.md`. **Manutenção evolutiva pendente, sem invalidar a entrega original:** refletir T10 e continuidade nas vistas/README, alinhando Markdown/HTML e coordenando arquivos globais com Pedro. Esquema 2, transações, retirada e exportação devem continuar corretos; resultados antigos não são nova execução. Política DAS depende de T02. **Revisão:** Matheus/Pedro.
- [ ] **T08 — evidências acadêmicas e protocolo (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/academico/EVIDENCIAS-E-PROTOCOLO.md`. **Aceite:** requisito→evidência, autoria/template preservados, lacuna IA/API confirmada com orientação, roteiro consentido de observação/devolutiva e registro agregado; não inventar participantes ou impacto. Não publicar pesquisa individual. **Revisão:** Pedro.
- [ ] Atualizar a comparação de funcionalidades com fontes primárias e limitações de acesso; existência em concorrente não prova necessidade para MEI ou facilidade técnica.

## Ordem e fronteiras de trabalho

1. Confirmar disponibilidade/ambiente e preencher um contrato por tarefa. A redistribuição de Raphael foi solicitada por Pedro; T10 tem contrato próprio, sem autorização para implementar os demais itens MEL-MEI automaticamente.
2. Preparar candidato/roteiro e ensaiar o já existente (T05/T09); não condicionar demonstração a novas funcionalidades não validadas.
3. T10 já está integrada: Raphael consolida evidências e segue T07, sem refazer `lib/annual/`. Matheus prioriza T09; Luchie mantém as pendências de T03/T08 e delimita a manutenção evolutiva de T04 com Pedro. T02 aguarda política/executor; T05 aguarda executor Android. Estes próximos passos preservam os responsáveis, não afirmam disponibilidade ou trabalho já iniciado. T01/T03 não são declaradas novamente executadas apenas por atualizar o checklist.
4. Integrar e congelar uma versão antes de novo ensaio. Mudança de dependência/assinatura durante validação invalida a identidade do candidato.
5. T10/MEL-MEI-02 e continuidade/MEL-MEI-01 já estão integradas. H01–H06 continuam propostas sujeitas a aprovação; H04, se escolhido, deve preservar entradas **e despesas** e ter dono único para tela anual/composição. H01/H05 não devem alterar o Histórico em paralelo. Lembrete diário/MEL-MEI-03 não é o DAS e não está autorizado por este checklist. Backup, fiado, recorrência, câmera/QR e IA não entram como “tarefa rápida”.

Pedro coordena alterações em `README.md`, `docs/hermes/REQUISITOS-ARQUITETURA.md`, modelos, totais, persistência e consolidação deste checklist. Um executor por vez em arquivos compartilhados; revisão cruzada é leitura/comentário, não edição simultânea de branch alheia. Ver [matriz de fronteiras](ESTADO-E-COORDENACAO.md#fronteiras-e-dependencias). Não há prazo estimado: prioridades/esforço são relativos.

## Pronto para revisão significa

- [ ] Critérios do contrato atendidos, sem ampliar escopo.
- [ ] Diff pequeno e apenas arquivos combinados; sem segredos, anexos, dados reais ou APK.
- [ ] Testes direcionados/análise/suíte executados quando pertinentes e possíveis, com resultado real ou bloqueio explícito.
- [ ] Para Android, identificar se foi simulação, build, instalação ou fluxo observado.
- [ ] Pendências/riscos anotados e revisão de Pedro/designado obtida; commit/merge/push não automáticos.
