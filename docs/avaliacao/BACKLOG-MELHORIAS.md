# NotaMei — feedbacks para melhorias futuras

Síntese compartilhável autorizada pelo proprietário. Origem e limites: [avaliação exploratória de 04/11/2026](FEEDBACK-MEI-2026-11-04.md), uma pessoa e dois instrumentos complementares. F1/F2 remetem aos documentos locais identificados nessa síntese. Os originais, contatos e imagens permanecem fora do Git. Os itens abaixo são propostas, não autorização de implementação, e não alteram os IDs RF, RN, US ou FB01–FB08.

## Como usar

Revalidar cada item no código/versão vigente antes de implementar. Separar necessidade relatada, hipótese de solução, regra de negócio e bug comprovado. Prioridade e esforço abaixo são sugestões técnicas relativas, sem prazo ou aceite do proprietário. Nenhum item foi implementado por este registro.

## MEL-MEI-01 — Continuidade dos valores entre meses

- Fonte: F1 seção J, p.5; F2 Q7 e Q14, pp.4–5.
- Necessidade: visualizar valores remanescentes do período anterior e acompanhar continuidade financeira.
- Situação: recorte autorizado e implementado localmente em 12/11/2026; integração e ensaio Android pendentes. O balanço mensal continua separado e não representa saldo bancário. Ver [contrato e evidências de continuidade](../colaboracao/MEL-MEI-01-CONTINUIDADE.md).
- Prioridade sugerida: alta para definição de escopo; esforço alto.
- Decisão aprovada em 12/11/2026: acumulado desde o primeiro registro elegível, sem saldo inicial manual; períodos civis e âmbitos explícitos, histórico parcial avisado e recálculo após edições/exclusões. Detalhes e limites no contrato acima.
- Critérios propostos: preservar o balanço do período; indicador acumulado separado e explicitamente limitado aos registros informados; centavos exatos; testes de virada de mês/ano e retroatividade; retiradas sem duplicação em Todos; nenhuma inferência de lucro/saldo bancário ou lançamento sintético duplicado.
- Relação: base para esclarecer MEL-MEI-04. Não alterar regra financeira por inferência.

## MEL-MEI-02 — Despesas no acompanhamento anual

- Fonte: F1 seção F, p.3.
- Necessidade: visualizar também o total de despesas na tela Ano.
- Situação: proposta funcional, não defeito da soma atual de entradas comerciais.
- Prioridade sugerida: média; esforço médio.
- Decisões: Negócio somente ou seleção explícita de âmbito? Apresentação mensal/anual? Saldo descritivo opcional, sem chamar de lucro.
- Critérios propostos: entradas e despesas externas separadas, ano explícito, retirada apresentada separadamente sem inflar despesa externa, testes de filtro/limites e preservação de interpretação de meses sem informação.

## MEL-MEI-03 — Lembrete de registrar movimentações

- Fonte: F1 seção J, p.5; F2 Q9, p.4.
- Necessidade: criar hábito de preencher os registros; sugestão de aviso à noite, após o expediente.
- Situação: recurso novo a avaliar, distinto do lembrete do DAS.
- Prioridade sugerida: média; esforço médio.
- Critérios propostos: opt-in, horário escolhido pela pessoa (não fixar noite), desativação simples, permissão contextual, IDs/canal separados do DAS, nenhum texto com dados financeiros na notificação, testes de reagendamento/cancelamento/fuso/permissão e distinção entre agendado e efetivamente entregue.

## MEL-MEI-04 — Tornar perceptível o efeito de Pagar-me

- Fonte: F1 seção D, pp.2–3, e seção J, p.5; F2 T5, p.2, e Q8, p.4.
- Necessidade: entender o débito no Negócio e crédito no Pessoal, inclusive a relação com continuidade entre meses.
- Situação: investigar compreensão/fluxo; NÃO registrar como ausência de operação vinculada. O código consultado já contém `saveWithdrawal` com duas pontas transacionais. O APK exato utilizado não foi identificado.
- Prioridade sugerida: alta para esclarecimento/reteste; esforço baixo para investigação, variável para eventual implementação.
- Próximo passo: confirmar o que a pessoa esperava, repetir com dados fictícios identificados, comparar as duas pontas e os resumos e verificar edição/exclusão conjunta.
- Critérios propostos: confirmação clara das duas pontas; compreender edição/exclusão conjunta, que recebeu nota neutra 3; preservar idempotência, transação e exclusão das internas dos totais gerais. Não duplicar recurso existente nem fazer transferência bancária.
- Dependência: MEL-MEI-01 para a expectativa intermensal.

## MEL-MEI-05 — Orientação inicial sobre Negócio/Pessoal e Histórico

- Fonte: F1 seção C, p.2; F2 Q4 e Q6, pp.3–4; F2 T3, p.2.
- Necessidade: reduzir dúvida inicial de classificação e necessidade de orientação para localizar/editar observação.
- Situação: melhoria de conteúdo/usabilidade; não concluir que a pessoa terminou sem compreender a separação. Ela declara compreensão posterior.
- Prioridade sugerida: média; esforço baixo a médio.
- Critérios propostos: exemplos curtos com valores fictícios, ajuda contextual sem aconselhamento fiscal, reteste de classificação e descoberta de edição antes da demonstração, registro de ajuda. Preservar possibilidade de pular o tour.

## MEL-MEI-06 — Reduzir atrito e aumentar clareza na instalação de teste

- Fonte: F1 seção J, p.5.
- Necessidade: lidar com desconfiança e avisos percebidos ao instalar APK fora de loja.
- Situação: barreira relatada, sem captura, texto exato ou causa técnica do aviso. Não afirmar bloqueio específico da Play Store/Play Protect.
- Prioridade sugerida: alta antes de ampliar distribuição; esforço médio/alto conforme canal escolhido.
- Critérios propostos: identificar pacote, versão, procedência e hash; rever assinatura/atualização e canal com Pedro; instruções claras e voluntárias; nunca recomendar desativar proteções; validar com aparelho de teste e preservar dados. Publicação/chaves exigem autorização própria.

## Validações pendentes, não novos pedidos do participante

- CSV, PDF e DAS: não usados nessa avaliação. Não considerar aprovados nem reprovados pelo MEI. T7 (exportar ou escolher tema) foi marcada como não tentada; não há comparação entre temas.
- O texto impresso do roteiro menciona achados técnicos prévios de PDF/modo escuro. Isso não é relato do entrevistado nem prova do estado do APK utilizado.
- Realizar nova sessão com versão/commit/APK identificado, duração observada, consentimento e reteste focado nas sugestões. A nota individual de recomendação 9/10 não é NPS populacional ou prova de adoção sustentada.
