# NotaMei — matriz de rastreabilidade e plano de verificação

**Revisão documental:** 2026-11-11. **Base:** `9076f3d`. Requisitos em [REQUISITOS-ARQUITETURA.md](../hermes/REQUISITOS-ARQUITETURA.md), vistas em [C4-NOTAMEI.md](C4-NOTAMEI.md), decisões em [ADRs](decisoes/README.md).

## 1. Como ler

- **Origem:** contexto de projeto, decisão do responsável ou síntese de feedback; não representa automaticamente uma regra fiscal ou demanda de todos os MEIs.
- **Estado de código:** presente, parcial ou proposto. Documentação de tarefa não implementa recurso.
- **Cobertura existente:** caminho de teste inspecionável, não resultado executado nesta revisão.
- **Execução:** só pode ser preenchida com comando, commit/candidato, ambiente, data e resultado reais. Nesta revisão não foram executados Flutter, ensaios Android, benchmarks ou nova avaliação com participantes.
- **RNF:** critérios/ambientes definidos no catálogo; metas novas continuam propostas, não promessas aprovadas de desempenho, disponibilidade ou segurança.

Os nomes BOOT, FIN, ANNUAL, REPO, MONEY, TOTALS, EX, REPORT, OUT, DAS e GATE identificam os elementos da vista C3. Não são serviços HTTP nem camadas independentes formalmente implementadas.

## 2. RNF → decisão/vista → verificação

| RNF | Decisão ou elemento C4 | Código / cobertura existente | Verificação e pendência |
| --- | --- | --- | --- |
| RNF01 | [ADR-001](decisoes/ADR-001-NUCLEO-LOCAL.md), C2/app + DB | [`entry_repository_test.dart`](../../test/data/entry_repository_test.dart), [`notamei_finance_test.dart`](../../test/finance/notamei_finance_test.dart) | T05: modo avião, 10 registros fictícios, reabertura e comparação; pendente. Teste unitário não comprova modo avião. |
| RNF02 | [ADR-002](decisoes/ADR-002-SQLITE-TRANSACOES.md), C3/REPO e sequência local | [`withdrawal_test.dart`](../../test/data/withdrawal_test.dart), [`withdrawal_ui_test.dart`](../../test/finance/withdrawal_ui_test.dart) | Injetar falha antes do commit, confirmar zero par parcial e retry sem duplicação; cobertura existente, sem nova execução. |
| RNF03 | [ADR-003](decisoes/ADR-003-CENTAVOS-EXATOS.md), C3/MONEY + TOTALS + ANNUAL | [`money_test.dart`](../../test/core/money_test.dart), [`withdrawal_totals_test.dart`](../../test/finance/withdrawal_totals_test.dart), [`annual_summary_test.dart`](../../test/annual/annual_summary_test.dart) | Casos de centavos, limites, datas e exclusão de internas; comparar inteiros esperados. Sem execução nova. |
| RNF04 | [ADR-001](decisoes/ADR-001-NUCLEO-LOCAL.md), C1/fronteira e C3/EX + OUT | [`export_screen_test.dart`](../../test/export/export_screen_test.dart), [`export_gateway_test.dart`](../../test/export/export_gateway_test.dart) | T07/T05: auditar opt-in, cancelamento e saída voluntária, registrar observação nativa; comportamento de backup do SO não certificado. |
| RNF05 | C3/FIN + ANNUAL + BOOT, interfaces e semântica | [`editorial_b_test.dart`](../../test/finance/editorial_b_test.dart), [`annual_income_screen_test.dart`](../../test/annual/annual_income_screen_test.dart), [`startup_screen_test.dart`](../../test/app/startup_screen_test.dart), [avaliação T03](../AVALIACAO-ACESSIBILIDADE-T03.md) | Revalidar 390 px/texto 2x e controles alcançáveis; TalkBack em Android é etapa própria. Marcação histórica de T03 não certifica qualquer candidato posterior. |
| RNF06 | [ADR-001](decisoes/ADR-001-NUCLEO-LOCAL.md), implantação Android | [T06 — versão/atualização](../entrega/VERSAO-E-ATUALIZACAO.md), [checklist T05](../colaboracao/CHECKLIST-EQUIPE.md) | Definir dois níveis de API, identificar APK/aparelhos e executar roteiro; não confundir build com aprovação dos fluxos. |
| RNF07 | [ADR-003](decisoes/ADR-003-CENTAVOS-EXATOS.md), C3/REPORT | [`pdf_export.dart`](../../lib/export/pdf_export.dart), [`pdf_export_test.dart`](../../test/export/pdf_export_test.dart) | Casos no limite e acima, sem truncamento; ativos/fonte, memória/tempo e saída nativa precisam de verificação. Não é revisão/correção de tipografia nesta tarefa. |
| RNF08 | C3/BOOT + DAS + GATE, [ADR-001](decisoes/ADR-001-NUCLEO-LOCAL.md) | [`das_schedule_test.dart`](../../test/das/das_schedule_test.dart), [`das_reminder_service_test.dart`](../../test/das/das_reminder_service_test.dart), [`startup_screen_test.dart`](../../test/app/startup_screen_test.dart) | Calendário e falha de refresh automatizados; T02 ainda define falha parcial; T05 observa bateria/fuso/permissão/entrega sem SLA. |
| RNF09 | [ADR-002](decisoes/ADR-002-SQLITE-TRANSACOES.md), C3/REPO | [`entry_repository.dart`](../../lib/data/entry_repository.dart); não há benchmark identificado para a meta nova | Proposta: base de 500 registros, 20 salvamentos, P95 ≤ 2 s; confirmar alvo e ambiente antes de medir. Zero resultado de desempenho declarado aqui. |
| RNF10 | [ADR-002](decisoes/ADR-002-SQLITE-TRANSACOES.md), C2/DB v2 | [`withdrawal_test.dart`](../../test/data/withdrawal_test.dart), [T06](../entrega/VERSAO-E-ATUALIZACAO.md) | Fixture de migração v1→v2, 10 registros preservados, preferências e atualização sem limpeza; não ensaiado nesta revisão. Sem downgrade ou restauração próprios. |

## 3. RF/FB → regra → decisão/componente → cobertura

| RF/FB | Regras / origem de escopo | Decisão / componente | Situação e evidência disponível |
| --- | --- | --- | --- |
| RF01 + FB01 | RN01–RN05, RN22, RN24; cadastro manual/sequencial | ADR-001/ADR-002/ADR-003; FIN, REPO, MONEY | Presentes; [`entry_sequence_test.dart`](../../test/finance/entry_sequence_test.dart), [`entry_repository_test.dart`](../../test/data/entry_repository_test.dart). |
| RF02 + FB02 | RN01, RN06, RN07, RN23; separação e filtros | ADR-003; FIN, TOTALS | Presentes; [`dashboard_scope_test.dart`](../../test/finance/dashboard_scope_test.dart), [`history_independent_filters_test.dart`](../../test/finance/history_independent_filters_test.dart). |
| RF03 | RN04, RN06–RN08, RN23; resumos sem interpretação bancária | ADR-003; FIN, TOTALS | Presente; [`withdrawal_totals_test.dart`](../../test/finance/withdrawal_totals_test.dart). |
| RF04 | RN04, RN05, RN12, RN23; consulta/correção e par vinculado | ADR-002; FIN, REPO | Presente; [`notamei_finance_test.dart`](../../test/finance/notamei_finance_test.dart), [`withdrawal_ui_test.dart`](../../test/finance/withdrawal_ui_test.dart). |
| RF05 | Necessidade adicional de gráfico a validar, sem RN nova inferida | Componente futuro a definir; nenhuma decisão de biblioteca aprovada | Não implementado; sem teste de funcionalidade existente a declarar. |
| RF06 | RN19–RN21; agenda pessoal, não DAS fiscal | ARQ-05; BOOT, DAS, GATE | Agendamento presente; [`das_interaction_test.dart`](../../test/das/das_interaction_test.dart). Entrega futura não comprovada. |
| RF07 | RN04, RN08, RN09, RN13; entradas comerciais do ano | ADR-003; ANNUAL, MONEY | Presente para entradas; [`annual_summary_test.dart`](../../test/annual/annual_summary_test.dart). T10 é extensão ainda não implementada. |
| RF08–09 + FB04/FB05 | Agrupamento legado; RN15–RN18 para relatórios | ADR-001/ADR-003; EX, REPORT, OUT | CSV/PDF presentes; [`csv_export_test.dart`](../../test/export/csv_export_test.dart), [`pdf_screen_test.dart`](../../test/export/pdf_screen_test.dart). Metas, comprovantes, fiado e sincronização continuam futuros e sem RF atômicos fechados. |
| RF10 | Fluxo de primeiro uso opcional, sem regra de domínio adicional inventada | BOOT e onboarding | Presente; [`onboarding_flow_test.dart`](../../test/onboarding/onboarding_flow_test.dart). |
| FB03 | Captura de compra requer formatos, confirmação e privacidade | Extensão proposta; sem componente de captura atual | Não implementado; requisitos/contrato a definir antes de câmera/consulta externa. |
| FB06 | Assistência exige confirmação e cálculo determinístico separado | Extensão proposta, não servidor/IA já existentes | Não implementado; nenhum resultado de IA no aplicativo declarado. |
| FB07 | Lite somente após lançamento | Decisão futura de modularidade/compatibilidade | Não implementado; nenhum novo pacote ou banco autorizado. |
| FB08 | RN08, RN10–RN14 e RN16; retirada já implementada | ADR-002/ADR-003; FIN, REPO, TOTALS | Presente; [`withdrawal_test.dart`](../../test/data/withdrawal_test.dart), [`withdrawal_csv_test.dart`](../../test/export/withdrawal_csv_test.dart). Não recriar como transferência bancária. |

## 4. Feedback recente → requisito → tarefa/evidência

**Origem comum:** [síntese de 04/11/2026](../avaliacao/FEEDBACK-MEI-2026-11-04.md) e [backlog com fonte por item](../avaliacao/BACKLOG-MELHORIAS.md). Uma pessoa em dois instrumentos; originais privados fora do Git. Associação abaixo é interpretação de planejamento, não teste novo ou aprovação de todo o backlog.

| Origem | Necessidade / relação | Decisão ou ponto de extensão | Tarefa / estado / verificação futura |
| --- | --- | --- | --- |
| MEL-MEI-01 | Continuidade entre meses; relaciona RF03/RF07 e RN07–RN09 | FIN/ANNUAL; regra de acumulado ainda não definida | Especificar antes de implementar; testar histórico parcial, retroatividade, virada de ano e internas. Sem saldo inicial ou carry-over automático aprovado. |
| MEL-MEI-02 | Despesas no Ano, extensão de RF07; RN13 preservada | ANNUAL/MONEY; ADR-003 preservado | [T10 de Raphael](../colaboracao/T10-DESPESAS-ANUAIS.md), atribuída, não implementada; testes no Windows e etapa Android separada. |
| MEL-MEI-03 | Hábito de registrar; não equivale ao lembrete DAS de RF06 | Novo RF e serviço/gateway a definir; nenhum componente diário atual | Proposta sem tarefa de implementação atribuída; opt-in, horário, cancelamento, fuso e observação nativa precisam de contrato próprio. |
| MEL-MEI-04 | Compreensão de Pagar-me; FB08/RF04 e RN10–RN14 | FIN/REPO/TOTALS; ADR-002/ADR-003 | Investigar compreensão e versão usada; retestar duas pontas e edição/exclusão sem declarar recurso ausente. Dependência conceitual com MEL-MEI-01. |
| MEL-MEI-05 | Classificação e descoberta da edição; RF02/RF04/RF10 | FIN/BOOT; conteúdo contextual a especificar | Proposta de usabilidade, sem nova implementação atribuída; reteste consentido com e sem ajuda, sem afirmar aprendizado comprovado. |
| MEL-MEI-06 | Confiança na instalação de APK; RNF06/RNF10, não RF financeiro | Implantação/canal/assinatura; decisão de Pedro | T05/T06 e plano de distribuição; texto/causa do alerta não identificados. Não recomendar desativar proteções nem publicar sem autorização. |

## 5. Registro de uma execução futura

Para cada cenário: registrar ID, requisito, commit/APK/hash quando pertinente, ambiente (Windows/Android real/emulador), dados sintéticos, procedimento, esperado, observado, resultado e referência sanitizada ao log. Identificar se foi build, teste automatizado, observação nativa ou sessão com participante. Falha, bloqueio e não execução são estados diferentes.

Para RNF09, medir do toque de confirmação até retorno bem-sucedido após persistência; registrar cada duração, ordenar as 20 amostras e aplicar P95 pelo método de posto mais próximo, sem descartar lentidão silenciosamente. Não executar esse ensaio na base real do participante. O alvo proposto de 2 s precisa de revisão antes de ser tratado como compromisso de qualidade.

Não há quatro endpoints/JSON de negócio a listar: comunicação atual é local. Se uma integração remota for aprovada, criar contrato próprio, regras de proteção/falha, exemplos explicitamente ilustrativos e rastreio a RF, sem reclassificar esta arquitetura como cliente-servidor.
