# Diagnóstico do NotaMei para planejamento da equipe

## Base e alcance

Auditoria estática da base `da4b2a4f0f1bb4f78f530e43cbcc9fa2cd039fb6`, branch `feature/exportacao-pdf`, após o commit do PDF. As orientações de colaboração desta pasta foram acrescentadas depois; não são funcionalidades novas do app.

O inventário da base tinha **107 arquivos rastreados**. Houve inspeção de conteúdo em **98 caminhos**: **61 por leitura integral** e **37 por extração reduzida/estrutural**. Outros **nove** foram apenas inventariados, incluindo oito binários e `.metadata`. Abrangeu os 26 Dart de `lib/`, 35 testes Dart, dois verificadores Python, 15 textos/configurações Android e dez documentos compartilháveis. Os testes Dart foram examinados por extração de casos/asserções, não integralmente linha a linha; lock e HTML tiveram análise estrutural/textual. Isso não é auditoria exaustiva de segurança nem revisão visual dos binários.

Não houve nova execução de testes/build, uso de aparelho ou instalação nesta auditoria. Contagens de testes de entregas anteriores são históricas. Pesquisa individual, dados financeiros, segredos, ignorados, dependências instaladas e builds ficaram fora do escopo. O manifesto de cobertura e o relatório bruto permanecem fora do Git, com Pedro.

## Já implementado — não atribuir como funcionalidade ausente

- Tour opcional/reabertura, quatro abas, visual V5, fontes locais.
- Entrada/saída manual, Negócio/Pessoal, editar/excluir e cadastro em sequência.
- Painel e Histórico por mês; filtros de âmbito e tipo independentes.
- Retirada vinculada e operações conjuntas/transacionais, esquema SQLite 2.
- Acompanhamento anual descritivo das entradas comerciais comuns.
- Configuração e agendamento local de lembrete pessoal do DAS.
- Exportação **CSV e PDF** em Ajustes, filtros/períodos/totais comuns, observações opt-in, salvar e compartilhar.

Rastreio: `lib/app/`, `lib/finance/`, `lib/data/`, `lib/annual/`, `lib/das/`, `lib/export/` e testes correspondentes. [Requisitos e RN](../hermes/REQUISITOS-ARQUITETURA.md), [retirada](../hermes/RETIRADA-TITULAR.md), [CSV](../hermes/EXPORTACAO-CSV.md), [PDF](../hermes/EXPORTACAO-PDF.md).

## Achados para priorizar

| Tema | Evidência e classificação | Encaminhamento |
| --- | --- | --- |
| Inicialização | `lib/main.dart` inicializa preferências/banco antes de `runApp`; o catch atual cobre o refresh DAS. Caminho estático sem tela própria de erro/retry, não falha provocada no aparelho. | Planejar recuperação visual não destrutiva com teste de falha injetada. |
| Refresh DAS | `enable` trata falha com tentativa de cancelamento/desativação; `refresh` só chama `schedule`. O gateway agenda uma janela sequencial. Risco de estado parcialmente atualizado, sem entrega perdida comprovada. | Definir com Pedro política de estado/aviso e cobrir erro parcial, retry e cancelamento falho. |
| Android real | Testes de gateways simulam plugins; PDF e atualização da retirada exigem evidência nativa consolidada. | Ensaiar versão exata com dados fictícios; verificar arquivo salvo/reaberto, compartilhamento, migração e reabertura. |
| Documentação C4 | Complementos reconhecem a evolução, mas partes dos diagramas/corpo ainda descrevem esquema 1, modelo anterior e operações antigas. | Atualizar fonte Markdown e HTML juntos, sem reportar limitações históricas como bugs atuais. |
| Contexto histórico | `CONTEXTO-NOTAMEI.md` é da migração e diz não haver exportação. A skill geral versionada também tinha esse texto; foi corrigida neste pacote. | Manter recortes históricos identificados e consultar código/README/RN atuais. |
| Datas | Formulário comum limita o seletor a 2020–1/1/2030; retirada/exportação usam intervalo maior. Ano acompanha ano corrente. Limitação de interface, não política fiscal. | Decidir alcance antes de harmonizar; seletor de ano é melhoria candidata. |
| Distribuição | Gradle release usa assinatura debug; versão é declarada no pubspec. Não há restaurador. | Plano de versão/assinatura com Pedro; não publicar ou trocar chave automaticamente; relatório não é backup. |
| Acessibilidade | Há adaptações e testes de texto ampliado; não foi ensaiado TalkBack nesta auditoria. | Observar rótulos/foco/erros antes de propor correção. |
| Escala | Repositório usa snapshot da tabela e Histórico monta widgets do mês. Não houve medição de lentidão. | Medir com dados sintéticos antes de exigir paginação/refatoração. |

Não há servidor, autenticação, integração bancária/fiscal, importação/restauração ou IA de produto implementados nesse recorte. Dependências transitivas de rede/QR no lock não provam essas funcionalidades. O anual não é apuração fiscal; retirada não é transferência real; lembrete agendado não é entrega garantida.

## Cuidados acadêmicos e de dados

Preservar autoria e template institucional. Confirmar com orientação o recorte de IA/API: usar IA no desenvolvimento não comprova IA dentro do app. Não declarar entrevistas, consentimento, cerimônias Scrum ou impacto social sem evidência. A pesquisa exploratória não demonstra representatividade de MEIs.

MIT do projeto e OFL das fontes estão em `LICENSE` e `assets/fonts/`. Registrar procedência da marca com Pedro; não presumir infração nem copiar recursos de concorrentes. Política efetiva de backup Android não foi certificada nesta auditoria; decidir recuperação é distinto de prometer backup do sistema.

## Decisão sugerida

Primeiro validar o que já existe, fechar inicialização/refresh e alinhar documentação. Depois escolher poucas melhorias locais do [benchmark](BENCHMARK-FUNCIONALIDADES.md), com tarefa pequena e aceite. [Checklist da equipe](CHECKLIST-EQUIPE.md).
