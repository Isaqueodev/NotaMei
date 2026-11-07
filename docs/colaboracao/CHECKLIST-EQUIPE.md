# Checklist proposto da equipe NotaMei

**Base da revisão de tarefas:** `a3e3764`, sincronizada com `origin/main`; o checklist original partia de `da4b2a4`. **Proprietário e integrador:** Pedro Isaque. A pedido de Pedro, Raphael Max passa a ter foco em desenvolvimento e testes no computador, pois não possui Android. As demais atribuições continuam propostas; não se presume ferramenta ou disponibilidade dos integrantes. Marcações de conclusão recebidas do remoto foram preservadas, não revalidadas nesta revisão.

Contexto: [diagnóstico e limites da auditoria](DIAGNOSTICO-REPOSITORIO.md), [benchmark](BENCHMARK-FUNCIONALIDADES.md), [guia para IAs](GUIA-IA-EQUIPE.md) e [contrato de tarefa](TAREFA-PARA-IA.md). CSV/PDF e retirada já existem: a tarefa é validar/preservar, não recriar.

**Novo insumo:** [feedback de 04/11/2026](../avaliacao/FEEDBACK-MEI-2026-11-04.md), de uma pessoa em dois instrumentos, e [backlog correspondente](../avaliacao/BACKLOG-MELHORIAS.md). T10 deriva de MEL-MEI-02; não significa que o recurso já foi implementado nem que todo o backlog foi autorizado.

## Pedro Isaque — decisões e integração

- [ ] Confirmar prioridades, disponibilidade e a divisão abaixo com os três.
- [ ] Escolher candidato de versão e ambiente para os testes; autorizar separadamente operação de aparelho e fixtures.
- [ ] Decidir política de falha do refresh DAS e alcance das datas antes de mudanças de regra.
- [ ] Manter custódia das chaves/assinatura e aprovar eventual mudança de versão/distribuição.
- [ ] Revisar diffs e evidências, resolver arquivos compartilhados e decidir commits/merge/publicação. O Hermes não é requisito para a contribuição dos demais.
- [ ] Confirmar com orientação o que conta como IA/API e quais evidências acadêmicas são exigidas.

### Tarefas retiradas da execução de Raphael

- [ ] **T02 — política e falha parcial do refresh DAS (prioridade 1; médio).** Pedro coordena a decisão e a designação de um executor; não há substituto presumido. Mantém o escopo de `lib/das/das_reminder_service.dart` e testes do serviço, com política definida antes de alterar código. **Aceite preservado:** erro no meio da janela, retry, preferência final e falha de cancelamento; acesso aos lançamentos não bloqueado; não prometer entrega de notificação. Testes automatizados e observação Android devem ser registrados separadamente. Informar a política para T04. **Revisão:** Matheus. Pendente, não concluída por esta redistribuição.
- [ ] **T05 — matriz Android da versão exata (prioridade 0; médio).** Pedro coordena e designa alguém com aparelho Android ou ambiente Android adequado; Raphael não é responsável pela execução nativa. Documento proposto: `docs/validacao/MATRIZ-ANDROID.md`. **Aceite preservado:** commit/artefato/aparelho/API; cadastro, edição, exclusão, cancelamento e reabertura; retirada/filtros; CSV/PDF, cancelamento e compartilhamento; modo avião/permissões; agendamento versus entrega observada. Migração v1→v2 somente com base sintética dedicada. Incluir o ensaio nativo de T10 após integração. Itens não executados permanecem pendentes; emulador não comprova entrega em aparelho físico. **Revisão:** Pedro.

## Matheus Rebelo — proposta de foco em inicialização e entrega

Skill principal: [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md).

- [X] **T01 — inicialização recuperável (prioridade 1; esforço médio).** Preparar e, se aprovado, implementar erro/retry para falha de abertura sem apagar dados. Escopo provável: `lib/main.dart`, nova tela de inicialização e teste próprio em `test/app/`; sem editar repositório/banco nesta fatia. **Aceite:** falha injetada exibe orientação segura; retry abre os registros; não recria/limpa base; falha de lembrete continua não bloqueante. **Revisão cruzada:** Raphael.
- [X] **T06 — plano de versão e atualização (prioridade 1; médio).** Documentar candidato, identidade, assinatura atual e atualização com base fictícia. Documento novo proposto: `docs/entrega/VERSAO-E-ATUALIZACAO.md`. **Aceite:** distinguir teste de produção, preservar registros/preferências no ensaio e registrar limites; qualquer alteração em Gradle/pubspec ou chaves depende de Pedro. Não publicar. **Revisão:** Pedro.
- [ ] **T09 — roteiro reproduzível de demonstração (prioridade 0; pequeno).** Documento novo proposto: `docs/entrega/ROTEIRO-DEMONSTRACAO.md`. Usar resultados de T05 e dados fictícios. **Aceite:** mostrar tour, sequência, filtros, retirada, anual, CSV/PDF e reabertura; ter contingência para falha de arquivo/lembrete; não chamar balanço de saldo/lucro nem agendamento de entrega. **Revisão:** Luchie.
- [ ] Depois das prioridades e de aprovação, assumir **H01 — busca textual no Histórico** do benchmark, sem sobrepor alterações de outra pessoa no mesmo arquivo.

## Raphael Max — desenvolvimento e testes sem depender de Android

**Ambiente informado por Pedro:** computador **Windows** e celular **iPhone**; não presumir acesso a Mac, Android, emulador ou SDK já instalado.

Skill principal: [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md). Para T07, usar também [documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md). A entrega de T10 é código Dart/Flutter e testes unitários/de widget no Windows, com Flutter configurado; não exige executar o aplicativo completo como versão Windows, web ou iOS. O iPhone não substitui a validação Android. Não atribuir a Raphael instalação de APK no iPhone, build iOS local no Windows, notificações, TalkBack ou compartilhamento nativo; Android permanece com o executor de T05. Emulador Android no Windows seria uma alternativa futura, não pré-requisito nem ambiente já confirmado.

- [ ] **T10 — despesas no acompanhamento anual (prioridade 1; médio; nova funcionalidade).** Responsável: **Raphael Max**. Origem: **MEL-MEI-02**, pedido do questionário para visualizar também despesas no Ano. Implementar entradas e despesas externas do **Negócio**, separadas por mês e no total do ano, sem incluir Pessoal ou retiradas e sem chamar o resultado de lucro/saldo bancário. Preservar histórico parcial, ano explícito e APIs existentes. **Escopo e aceite completos:** [contrato T10](T10-DESPESAS-ANUAIS.md). **Entrega de Raphael:** código, testes unitários/de widget e resultados reais executados no computador. **Revisão:** Matheus/Pedro; **validação Android:** T05, coordenada por Pedro, em etapa separada. Status: atribuída para desenvolvimento, ainda não implementada.
- [ ] **T07 — privacidade e procedência (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/entrega/PRIVACIDADE-E-RECURSOS.md`. **Aceite:** mapear dados locais/arquivos/cache/destinos; explicar que notas desligadas não anonimizam; registrar MIT/OFL e confirmar origem da marca com Pedro; não prometer limpeza/backup Android. Sem alterar Manifest por inferência. **Revisão:** Luchie/Pedro.
- [ ] Apoiar revisão de código e testes automatizados das melhorias escolhidas; filtros e retiradas não podem regredir. Na revisão de T01/T03, distinguir evidência automatizada de ensaio nativo feito por outro integrante; não assumir execução de TalkBack ou testes físicos Android.

## Luchie Bonates — proposta de foco em acessibilidade e documentação

Skill principal: [documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md). A divisão não impede sua participação em código/testes.

- [x] **T03 — rótulos, foco e acessibilidade (prioridade 1; pequeno/médio).** Observar primeiro; se necessário e aprovado, alterar somente o formulário comum e teste semântico novo. **Aceite:** TalkBack identifica valor/observação, erros/foco são compreensíveis e texto ampliado/teclado não impedem salvar/cancelar; sequência e regras preservadas. Sem defeito observado, registrar avaliação em vez de inventar bug. **Revisão:** Raphael.
- [ ] **T04 — atualizar arquitetura e histórico (prioridade 1; médio).** Reservar `docs/arquitetura/C4-NOTAMEI.md`, `c4-notamei.html`, `docs/hermes/CONTEXTO-NOTAMEI.md` e `EXPORTACAO-CSV.md`. **Aceite:** modelo/esquema 2, transações, retirada e exportação corretos; Markdown/HTML coerentes/offline; recortes antigos identificados; sem apresentar contagem antiga de testes como execução nova. Política DAS depende de T02; demais correções documentais não precisam esperar. A skill geral já foi corrigida neste pacote. **Revisão:** Matheus/Pedro.
- [ ] **T08 — evidências acadêmicas e protocolo (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/academico/EVIDENCIAS-E-PROTOCOLO.md`. **Aceite:** requisito→evidência, autoria/template preservados, lacuna IA/API confirmada com orientação, roteiro consentido de observação/devolutiva e registro agregado; não inventar participantes ou impacto. Não publicar pesquisa individual. **Revisão:** Pedro.
- [ ] Atualizar a comparação de funcionalidades com fontes primárias e limitações de acesso; existência em concorrente não prova necessidade para MEI ou facilidade técnica.

## Ordem e fronteiras de trabalho

1. Confirmar disponibilidade/ambiente e preencher um contrato por tarefa. A redistribuição de Raphael foi solicitada por Pedro; T10 tem contrato próprio, sem autorização para implementar os demais itens MEL-MEI automaticamente.
2. Preparar candidato/roteiro e ensaiar o já existente (T05/T09); não condicionar demonstração a novas funcionalidades não validadas.
3. Raphael desenvolve T10 em `lib/annual/` e `test/annual/`, sem sobrepor os arquivos dos colegas. T02 aguarda política e executor designados por Pedro; T04/T07/T08 podem produzir documentos próprios. Não reabrir nem declarar novamente executadas T01/T03 apenas pela atualização deste checklist.
4. Integrar e congelar uma versão antes de novo ensaio. Mudança de dependência/assinatura durante validação invalida a identidade do candidato.
5. A próxima evolução atribuída a Raphael é T10, baseada no feedback novo, não uma escolha automática de H01–H06. Continuidade entre meses (MEL-MEI-01) ainda exige decisões financeiras; lembrete diário (MEL-MEI-03) depende de validação nativa e não substitui esta tarefa. Backup, fiado, recorrência, câmera/QR e IA não entram como “tarefa rápida”.

Pedro coordena alterações em `README.md`, `docs/hermes/REQUISITOS-ARQUITETURA.md`, modelos, totais e persistência. Revisão cruzada é leitura/comentário; não implica editar a branch alheia. Não há prazo estimado: prioridades e esforço são relativos.

## Pronto para revisão significa

- [ ] Critérios do contrato atendidos, sem ampliar escopo.
- [ ] Diff pequeno e apenas arquivos combinados; sem segredos, anexos, dados reais ou APK.
- [ ] Testes direcionados/análise/suíte executados quando pertinentes e possíveis, com resultado real ou bloqueio explícito.
- [ ] Para Android, identificar se foi simulação, build, instalação ou fluxo observado.
- [ ] Pendências/riscos anotados e revisão de Pedro/designado obtida; commit/merge/push não automáticos.
