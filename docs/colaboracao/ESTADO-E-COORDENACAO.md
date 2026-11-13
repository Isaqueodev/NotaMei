# Estado e coordenação das tarefas NotaMei

**Reconciliação documental:** 12/11/2026. **Código auditado:** `0cacabcfbb3087a7adc23e2ac3f62531319c8940` (`0cacabc`). Proprietário/integrador: **Pedro Isaque**. Este registro não modifica responsáveis nem autoriza funcionalidades novas; consolida o [checklist](CHECKLIST-EQUIPE.md), contratos, PRs integradas e evidências da auditoria.

A auditoria anterior à abertura desta PR consultou as 27 PRs existentes, suas descrições/arquivos e revisões pertinentes, issues e branches: naquele instante não havia PRs/issues abertas. Isso não comprova ausência de trabalho local/offline. Não confundir item atribuído, diagnóstico entregue, código integrado, teste automatizado aprovado e ensaio Android observado.

## Estado por tarefa

| ID | Responsável preservado | Entrega comprovada | Pendência / fronteira |
| --- | --- | --- | --- |
| T01 | Matheus; revisão de Raphael | Inicialização recuperável integrada, PRs #10/#11; 2 testes específicos aprovados na auditoria. | Não recriar. Ensaio Android fica em T05; o teste com snapshot pré-carregado não cobre toda falha real de abertura. |
| T02 | Pedro coordena e designa executor; Matheus revisa | O DAS existe, e falha de lembrete não bloqueia a abertura do app. | Ainda falta fechar política de falha parcial de `refresh`, retry/preferências/cancelamento. Não atribuir automaticamente a Raphael. |
| T03 | Luchie; Raphael revisa código/testes | Diagnóstico inicial integrado pela #18; #20 reconhece a entrega e mantém pendências. | Aceite integral aberto: foco/erros/teclado e TalkBack. Cenário de sequência 390 px/texto 2x continua não aprovado. Android com executor adequado, não com o iPhone de Raphael. |
| T04 | Luchie; Matheus/Pedro revisam | Entrega original integrada pelas #22/#24; complemento de requisitos/ADRs/rastreabilidade na #23. | Manutenção evolutiva das vistas C4/HTML/README para T10/continuidade, coordenada com Pedro; não invalidar nem duplicar a entrega original. |
| T05 | Pedro coordena e designa executor Android | Candidato de teste identificado em [T06](../entrega/VERSAO-E-ATUALIZACAO.md#9-registro-complementar-do-candidato-de-teste--12112026). | Matriz `docs/validacao/MATRIZ-ANDROID.md` não localizada na base; build não comprova cadastro/exportação/notificação/atualização nativos. |
| T06 | Matheus; Pedro revisa | Plano documental integrado na #14; cenário fictício preservado e candidato real registrado em complemento. | Ensaio de atualização/preservação depende de T05; nenhuma assinatura de produção ou publicação autorizada. |
| T07 | Raphael; Luchie/Pedro revisam | Escopo definido no checklist, viável sem Android. | `docs/entrega/PRIVACIDADE-E-RECURSOS.md` não localizado na base. Mapear dados/arquivos/cache/destinos/licenças/procedência; sem prometer backup/limpeza do SO. |
| T08 | Luchie; Pedro revisa | Escopo definido no checklist. | `docs/academico/EVIDENCIAS-E-PROTOCOLO.md` não localizado. Produzir requisito→evidência/protocolo sem inventar participantes, impacto, horas ou IA/API implementada. |
| T09 | Matheus; Luchie revisa | Caminho previsto existe. | `docs/entrega/ROTEIRO-DEMONSTRACAO.md` está vazio na base. Redigir com dados fictícios e esperado/contingência; só declarar execução após evidência T05. |
| T10 | Raphael; Matheus/Pedro revisam | Código/testes integrados na #25, commit `400d126`; 12 testes anuais aprovados na auditoria de integração. | Não reimplementar. [Contrato](T10-DESPESAS-ANUAIS.md) distingue planejamento histórico de execução posterior; Android permanece em T05. |

A correção de acentos/cedilha de Matheus (#26) está integrada e deve ser preservada. Não é a mesma coisa que a dívida de assets/fontes do PDF. A continuidade entre meses (#27) também está integrada, no [recorte sem saldo inicial manual](MEL-MEI-01-CONTINUIDADE.md), separado do balanço mensal.

## Próximos passos dos integrantes

- **Matheus:** priorizar T09; manter T06 coerente com o candidato escolhido, sem declarar ensaio realizado. H01 (busca) continua proposta posterior, não tarefa já iniciada/autorizada por esta PR.
- **Raphael:** consolidar a entrega T10 e produzir T07. Preservar Windows+iPhone; não exigir instalação de APK, TalkBack ou build iOS no Windows. H04 (seletor de ano), se aprovado futuramente, deve preservar entradas **e despesas** e os limites de T10.
- **Luchie:** registrar/resolver as pendências da T03 com evidência e executor Android adequado, produzir T08 e combinar com Pedro um recorte de manutenção evolutiva de T04.
- **Pedro:** confirmar disponibilidade e executor de T02/T05, custodiar assinatura, coordenar arquivos globais e decidir responsáveis pelas falhas técnicas. Não atribuir todas as falhas ao último autor.

Não há prazo presumido nem mudança automática de disponibilidade/responsabilidade. H01–H06, lembrete diário, backup, fiado, captura e IA continuam sujeitos a contrato e aprovação próprios.

<a id="fronteiras-e-dependencias"></a>

## Fronteiras e dependências

| Sobreposição | Prevenção combinada |
| --- | --- |
| T03 / manutenção visual de Matheus | Um executor por vez em `entry_form_screen.dart` e testes da sequência. Partir da main atual; revisão não significa edição simultânea. |
| H01 / H05 / Histórico | Integrar busca e ordenação sequencialmente; preservar mês/âmbito/tipo, edição e par de retirada. |
| T10 / H04 / visual do Ano | T10 já integrada. Contrato futuro de H04 deve preservar despesas, entradas, ano civil e overflow; reservar tela anual e `notamei_app.dart` para um executor. |
| T01 / T02 / T04 | T01 controla acesso ao app; T02 decide estado do lembrete após falha parcial; T04 documenta. Não bloquear lançamentos nem duplicar políticas no serviço/catch da inicialização. |
| T04 / rastreabilidade / requisitos | Pedro coordena arquivos globais. Vistas C4/HTML permanecem fora do diff desta reconciliação: precisam de manutenção evolutiva e renderização conjunta em recorte próprio. |
| T06 / T07 / T08 | T06 registra candidato/assinatura/atualização; T07 registra dados/licenças/saída; T08 registra evidências/protocolo. Usar definições coerentes, sem prometer backup, limpeza, publicação ou ensaio inexistentes. |
| T05 / T09 / T03 / T10 | Identificar o mesmo candidato de APK/commit. Pode haver rascunho de roteiro e teste no computador antes do ensaio; nenhum deles comprova operação nativa. |
| Checklist global | Consolidar status numa atualização coordenada por Pedro, evitando três edições concorrentes. Cada integrante entrega evidências no contrato/arquivo próprio. |

Não foi detectado conflito textual ativo entre PRs abertas na auditoria anterior à abertura desta PR. A matriz acima registra riscos e dependências, não merges que falharam. Branch antiga com commit exclusivo pode conter dados já incorporados de outra forma: não reintegrar só pelo contador de commits; comparar conteúdo.

<a id="verificacao-e-limites"></a>

## Verificação e limites

A execução abaixo ocorreu na auditoria de **12/11/2026**, com o código de `0cacabc`, no Windows do integrador. Logs e respostas completas de API ficam fora do Git. Esta PR somente documental referencia esses resultados; não declara nova execução de Flutter ou do computador dos colaboradores.

| Comando / grupo | Resultado registrado |
| --- | --- |
| `flutter analyze --no-pub` | Sem problemas, exit 0. |
| Direcionados continuidade/painel/retirada/anual | 37 aprovações, exit 0. Comando completo no [registro T10](T10-DESPESAS-ANUAIS.md#evidência-de-integração--12112026). |
| `flutter test --no-pub --machine` | 157 aprovações, 10 erros e 1 falha; exit 1. **Suíte não aprovada integralmente.** |
| Inicialização | 2 testes aprovados em `test/app/startup_screen_test.dart`. |
| Anual | 5 testes de resumo e 7 de tela aprovados em `test/annual/`. |
| Baseline limpo de `dd73ea5` | 141 aprovações e os mesmos 11 casos não aprovados, comparados por arquivo/nome; nenhum caso adicional. |

Os 11 casos são cinco de PDF, quatro de UI/texto ampliado e dois de tema/assets. Os logs de assets/PDF incluem `Unable to load asset: "assets/fonts/Inter.ttf"`; há também divergência de cor esperada. Os casos não necessariamente têm a mesma causa. Esta PR não corrige fontes, tema, testes ou lógica.

T05, T07 e T08 continuam sem os documentos combinados; T09 continua vazio. Não foram criados placeholders para marcar essas tarefas como entregues. Não houve operação de aparelho, limpeza de banco, nova coleta com participantes nem publicação de dados de pesquisa nesta reconciliação.
