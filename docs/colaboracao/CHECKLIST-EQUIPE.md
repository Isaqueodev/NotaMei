# Checklist proposto da equipe NotaMei

**Base analisada:** `da4b2a4`. **Proprietário e integrador:** Pedro Isaque, único usuário de Hermes no momento. Matheus Rocha, Raphael Max e Luchie Bonates podem usar outras IAs; não se presume ferramenta, competência, disponibilidade ou aceite de papel. Esta é uma proposta para Pedro/equipe validarem, não ordem automática de implementação.

Contexto: [diagnóstico e limites da auditoria](DIAGNOSTICO-REPOSITORIO.md), [benchmark](BENCHMARK-FUNCIONALIDADES.md), [guia para IAs](GUIA-IA-EQUIPE.md) e [contrato de tarefa](TAREFA-PARA-IA.md). CSV/PDF e retirada já existem: a tarefa é validar/preservar, não recriar.

## Pedro Isaque — decisões e integração

- [ ] Confirmar prioridades, disponibilidade e a divisão abaixo com os três.
- [ ] Escolher candidato de versão e ambiente para os testes; autorizar separadamente operação de aparelho e fixtures.
- [ ] Decidir política de falha do refresh DAS e alcance das datas antes de mudanças de regra.
- [ ] Manter custódia das chaves/assinatura e aprovar eventual mudança de versão/distribuição.
- [ ] Revisar diffs e evidências, resolver arquivos compartilhados e decidir commits/merge/publicação. O Hermes não é requisito para a contribuição dos demais.
- [ ] Confirmar com orientação o que conta como IA/API e quais evidências acadêmicas são exigidas.

## Matheus Rebelo — proposta de foco em inicialização e entrega

Skill principal: [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md).

- [ ] **T01 — inicialização recuperável (prioridade 1; esforço médio).** Preparar e, se aprovado, implementar erro/retry para falha de abertura sem apagar dados. Escopo provável: `lib/main.dart`, nova tela de inicialização e teste próprio em `test/app/`; sem editar repositório/banco nesta fatia. **Aceite:** falha injetada exibe orientação segura; retry abre os registros; não recria/limpa base; falha de lembrete continua não bloqueante. **Revisão cruzada:** Raphael.
- [ ] **T06 — plano de versão e atualização (prioridade 1; médio).** Documentar candidato, identidade, assinatura atual e atualização com base fictícia. Documento novo proposto: `docs/entrega/VERSAO-E-ATUALIZACAO.md`. **Aceite:** distinguir teste de produção, preservar registros/preferências no ensaio e registrar limites; qualquer alteração em Gradle/pubspec ou chaves depende de Pedro. Não publicar. **Revisão:** Pedro.
- [ ] **T09 — roteiro reproduzível de demonstração (prioridade 0; pequeno).** Documento novo proposto: `docs/entrega/ROTEIRO-DEMONSTRACAO.md`. Usar resultados de T05 e dados fictícios. **Aceite:** mostrar tour, sequência, filtros, retirada, anual, CSV/PDF e reabertura; ter contingência para falha de arquivo/lembrete; não chamar balanço de saldo/lucro nem agendamento de entrega. **Revisão:** Luchie.
- [ ] Depois das prioridades e de aprovação, assumir **H01 — busca textual no Histórico** do benchmark, sem sobrepor alterações de outra pessoa no mesmo arquivo.

## Raphael Max — proposta de foco em lembretes e qualidade Android

Skill principal: [validação Android](../../.agents/skills/notamei-validacao-android/SKILL.md). Alteração de código segue também a skill geral/contrato de implementação.

- [ ] **T02 — política e falha parcial do refresh DAS (prioridade 1; médio).** Escopo provável exclusivo: `lib/das/das_reminder_service.dart` e testes do serviço. **Dependência:** Pedro decidir ativo com aviso, desativado ou estado indeterminado. **Aceite:** testar erro no meio da janela, retry, preferência final e falha de cancelamento; não bloquear acesso aos lançamentos nem prometer notificação entregue. Informar a política para T04 atualizar a documentação. **Revisão:** Matheus.
- [ ] **T05 — matriz Android da versão exata (prioridade 0; médio).** Documento novo proposto: `docs/validacao/MATRIZ-ANDROID.md`. **Aceite:** identificar commit/artefato/aparelho/API; cadastrar, editar, excluir, cancelar e reabrir; testar retirada e filtros; salvar/reabrir CSV/PDF, cancelar e compartilhar; modo avião e permissões; agendamento versus entrega observada. Migração v1→v2 só com base sintética em ambiente dedicado. Resultados não executados permanecem pendentes. **Revisão:** Pedro.
- [ ] **T07 — privacidade e procedência (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/entrega/PRIVACIDADE-E-RECURSOS.md`. **Aceite:** mapear dados locais/arquivos/cache/destinos; explicar que notas desligadas não anonimizam; registrar MIT/OFL e confirmar origem da marca com Pedro; não prometer limpeza/backup Android. Sem alterar Manifest por inferência. **Revisão:** Luchie/Pedro.
- [ ] Apoiar os testes/aceites das melhorias escolhidas; filtros e retiradas não podem regredir.

## Luchie Bonates — proposta de foco em acessibilidade e documentação

Skill principal: [documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md). A divisão não impede sua participação em código/testes.

- [ ] **T03 — rótulos, foco e acessibilidade (prioridade 1; pequeno/médio).** Observar primeiro; se necessário e aprovado, alterar somente o formulário comum e teste semântico novo. **Aceite:** TalkBack identifica valor/observação, erros/foco são compreensíveis e texto ampliado/teclado não impedem salvar/cancelar; sequência e regras preservadas. Sem defeito observado, registrar avaliação em vez de inventar bug. **Revisão:** Raphael.
- [ ] **T04 — atualizar arquitetura e histórico (prioridade 1; médio).** Reservar `docs/arquitetura/C4-NOTAMEI.md`, `c4-notamei.html`, `docs/hermes/CONTEXTO-NOTAMEI.md` e `EXPORTACAO-CSV.md`. **Aceite:** modelo/esquema 2, transações, retirada e exportação corretos; Markdown/HTML coerentes/offline; recortes antigos identificados; sem apresentar contagem antiga de testes como execução nova. Política DAS depende de T02; demais correções documentais não precisam esperar. A skill geral já foi corrigida neste pacote. **Revisão:** Matheus/Pedro.
- [ ] **T08 — evidências acadêmicas e protocolo (prioridade 1; pequeno/médio).** Documento novo proposto: `docs/academico/EVIDENCIAS-E-PROTOCOLO.md`. **Aceite:** requisito→evidência, autoria/template preservados, lacuna IA/API confirmada com orientação, roteiro consentido de observação/devolutiva e registro agregado; não inventar participantes ou impacto. Não publicar pesquisa individual. **Revisão:** Pedro.
- [ ] Atualizar a comparação de funcionalidades com fontes primárias e limitações de acesso; existência em concorrente não prova necessidade para MEI ou facilidade técnica.

## Ordem e fronteiras de trabalho

1. Confirmar tarefas e regras com Pedro; preencher um contrato por tarefa.
2. Preparar candidato/roteiro e ensaiar o já existente (T05/T09); não condicionar demonstração a novas funcionalidades não validadas.
3. Executar T01/T02/T03 em arquivos separados, se aprovadas; T04/T07/T08 podem produzir documentos próprios sem editar os arquivos dos colegas.
4. Integrar e congelar uma versão antes de novo ensaio. Mudança de dependência/assinatura durante validação invalida a identidade do candidato.
5. Somente depois escolher H01–H06 do benchmark. Backup, fiado, recorrência, câmera/QR e IA não entram como “tarefa rápida”.

Pedro coordena alterações em `README.md`, `docs/hermes/REQUISITOS-ARQUITETURA.md`, modelos, totais e persistência. Revisão cruzada é leitura/comentário; não implica editar a branch alheia. Não há prazo estimado: prioridades e esforço são relativos.

## Pronto para revisão significa

- [ ] Critérios do contrato atendidos, sem ampliar escopo.
- [ ] Diff pequeno e apenas arquivos combinados; sem segredos, anexos, dados reais ou APK.
- [ ] Testes direcionados/análise/suíte executados quando pertinentes e possíveis, com resultado real ou bloqueio explícito.
- [ ] Para Android, identificar se foi simulação, build, instalação ou fluxo observado.
- [ ] Pendências/riscos anotados e revisão de Pedro/designado obtida; commit/merge/push não automáticos.
