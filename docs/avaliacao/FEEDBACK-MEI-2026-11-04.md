# Avaliação exploratória do NotaMei — 04/11/2026

## Escopo e origem

Esta síntese registra necessidades e oportunidades de melhoria obtidas em um questionário de feedback e uma entrevista semiestruturada, ambos respondidos **pela mesma pessoa MEI**. Há **uma pessoa participante e dois instrumentos complementares**. O relatório posterior é uma síntese derivada, não uma terceira coleta.

A publicação desta síntese na documentação foi autorizada pelo proprietário do projeto. Os instrumentos contêm autorização de uso de síntese sem nome. Os PDFs preenchidos, contatos, assinaturas, imagens e outros dados identificáveis **não são versionados**. Este documento usa paráfrases, não transcrições de falas. Em amostra pequena, a omissão do nome não garante anonimato irreversível; evitar acrescentar detalhes de perfil ou aparelho.

### Fontes locais, não anexadas ao Git

- **F1:** `Questionario_Feedback_NotaMei_MEI-v2_RESPONDIDO-1.pdf`, cinco páginas.
- **F2:** `NotaMei_Entrevista_MEI_Feedback_RESPONDIDO-1.pdf`, seis páginas.
- **F3:** `NotaMei_Relatorio_Feedback_MEI_2026-11-04-1.pdf`, sete páginas; síntese de F1/F2.

Os nomes identificam os arquivos consultados, não links públicos. A coleta está datada de 04/11/2026. Os originais são preservados fora do repositório.

## Contexto e limites

Foi registrado uso no próprio celular e tema Sistema. O questionário indica versão `1.0.0 (MVP)`, mas o campo de versão/commit/APK da entrevista está em branco. **Não se vincula a avaliação a um commit específico.** Frequência semanal declarada não comprova duração total ou adoção sustentada. O próprio participante ressalvou uso insuficiente para consolidar a avaliação geral. [F1 A/K; F2 p.1 e Q10]

Os formulários foram recebidos preenchidos: as tarefas abaixo são marcações da ficha, não observações presenciadas pelo elaborador desta síntese. Não há tempos medidos, vídeo ou logs de cada ação. O fechamento destinado à confirmação final da síntese ficou sem preenchimento; a devolutiva confirmada continua pendente. [F2 pp.2 e 6]

Os respondentes do diagnóstico inicial não equivalem a testadores do aplicativo. Não somar automaticamente esta pessoa aos nove respondentes históricos: a possível sobreposição não foi verificada.

## Tarefas registradas

Os códigos referem-se à **entrevista efetivamente respondida**, não ao roteiro antigo do trabalho extensionista.

| Código | Atividade | Marcação recebida |
| --- | --- | --- |
| T1 | Registrar entrada fictícia no Negócio | Sem ajuda |
| T2 | Registrar saída fictícia no Negócio | Sem ajuda |
| T3 | Encontrar lançamento e editar observação | Com ajuda de interface |
| T4 | Alternar Negócio, Pessoal e Todos | Sem ajuda |
| T5 | Registrar retirada e consultar os âmbitos | Sem ajuda |
| T6 | Consultar o acompanhamento anual | Sem ajuda |
| T7 | Tentar exportar CSV/PDF ou escolher tema | Não tentou |

**Consolidado:** cinco tarefas sem ajuda, uma com ajuda e uma não tentada. Nenhuma foi marcada como não concluída. Não significa que sete tarefas foram realizadas nem que todos os fluxos foram validados. Não houve tarefa dedicada de exclusão ou comparação entre temas. [F2 p.2]

## Achados integrados

- **Utilidade percebida inicial:** organização dos registros no celular, lançamentos, filtros e visualização anual receberam avaliações favoráveis. Isso não mede ganho financeiro, produtividade ou impacto comunitário. [F1 C/E/F/J; F2 Q3 e Q11–Q12]
- **Avaliação geral com ressalva:** recomendação individual de **9/10** e intenção de continuar, mas facilidade geral neutra com declaração de uso insuficiente. Preservar essas evidências juntas; não converter em SUS, NPS populacional ou aprovação irrestrita. [F1 J; F2 Q10/Q15]
- **Classificação e edição:** dúvida inicial entre Negócio/Pessoal e ajuda registrada em T3 coexistem com respostas posteriores favoráveis. Não presumir autonomia completa ou atribuir aprendizado a uma intervenção não documentada. [F1 C; F2 T3 e Q4–Q6]
- **Continuidade entre meses:** necessidade recorrente de acompanhar valores remanescentes do período anterior. É demanda de escopo, não prova de erro no balanço mensal. [F1 J; F2 Q7/Q14]
- **Anual:** consulta de entradas bem avaliada, com pedido de visualizar também despesas. [F1 F; F2 Q12]
- **Pagar-me:** expectativa de débito no Negócio e crédito no Pessoal, apesar de T5 sem ajuda. Edição/exclusão conjunta recebeu resposta neutra. A retirada vinculada já está documentada e implementada; investigar compreensão, efeito visual ou continuidade temporal antes de propor outra operação. O build utilizado é desconhecido. [F1 D/J; F2 T5/Q8; documentação de retirada]
- **Hábito:** sugestão de lembrete diário para registrar movimentações, distinto do lembrete do DAS. Horário noturno é sugestão, não configuração obrigatória aprovada. [F1 J; F2 Q9]
- **Instalação:** barreira de confiança percebida na instalação por APK, sem captura ou texto exato do alerta. Não atribuir causa a Play Store/Play Protect sem evidência e não recomendar desativar proteções. [F1 J]

## Recursos não avaliados e incidentes

DAS e exportações CSV/PDF **não foram usados**. A tarefa alternativa T7 não foi tentada e não permite validar seleção de tema. Esses recursos não foram aprovados nem reprovados pelo participante. [F1 G/H; F2 T7/Q12]

Não houve problema percebido relatado na pergunta sobre incidentes. Isso não comprova ausência de bugs. A nota técnica impressa no roteiro sobre PDF/modo escuro é instrução da equipe, não resposta do MEI nem identificação do APK utilizado. Defeitos técnicos encontrados em outras revisões devem ter evidências próprias. [F2 Q13 e nota na p.2]

## Encaminhamentos

As seis necessidades estão no [backlog de melhorias](BACKLOG-MELHORIAS.md), com origem, decisões abertas e critérios propostos. Os IDs `MEL-MEI-01` a `MEL-MEI-06` são locais desta avaliação; **não renumeram RF, RN, US ou FB01–FB08**.

O registro não autoriza implementação, não altera regras financeiras nem promete prazos. Revalidar o código vigente e discutir o escopo com Pedro antes de desenvolver. O balanço dos registros não é saldo bancário nem lucro; retirada não transfere dinheiro; relatórios não são backups restauráveis.

Para a próxima sessão: identificar APK/commit ou hash, preservar dados existentes, usar exemplos fictícios, separar tentativas com e sem ajuda, esclarecer a expectativa de continuidade e registrar a devolutiva somente quando realizada.

## Contribuição acadêmica delimitada

A avaliação documenta escuta individual externa e subsidia revisão do produto. Pode integrar metodologia, resultados e propostas do trabalho extensionista. **Não comprova representatividade, parceria formal, horas de campo, impacto financeiro ou cumprimento integral da disciplina.** A ampliação, devolutiva e aceitação acadêmica dependem de evidências e orientação próprias.
