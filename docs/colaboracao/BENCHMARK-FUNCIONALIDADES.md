# Benchmark — melhorias locais e de baixa complexidade para o NotaMei

## Método e limites

Comparação documental com fontes primárias recuperadas para esta análise, confrontada com a base `da4b2a4` do NotaMei. Não houve instalação/teste dos concorrentes, estudo com usuários, medição de produtividade, comparação de preços ou avaliação de segurança. Uma funcionalidade aparecer em outro produto não prova demanda dos MEIs nem facilidade de implementação no nosso código. **Esforço e adequação abaixo são avaliação técnica/proposta da equipe, não informação dos fabricantes.**

Cashew/Ivy são referências de finanças pessoais; Organizze também serve como referência de interação. Não foram tratados como produtos exclusivamente para MEIs. O App Sebrae fornece o contraponto ligado a pequenos negócios. Sem ranking de popularidade ou recomendação comercial.

## Referências comparáveis

| Referência | O que a fonte primária documenta | Parâmetro para o NotaMei |
| --- | --- | --- |
| Cashew | README apresenta app em Flutter, distribuição Android, pesquisa/filtros, categorias personalizadas e orçamento por períodos.[1] | Buscar e filtrar com clareza; a linguagem Flutter não torna a arquitetura ou código automaticamente reutilizáveis. |
| Ivy Wallet | README descreve controle manual de finanças Android em Kotlin/Compose; avisa que os desenvolvedores originais deixaram de manter o projeto em 5/11/2024.[5] | Referência de conceito manual/simplicidade; não recomendar como base mantida nem portar arquitetura para Flutter sem análise. |
| Organizze Android | Ajuda oficial explica atalhos de período e filtros de relatórios, incluindo categoria/balanço; outro artigo documenta filtros de lançamentos por categoria, tipo e tags.[9][10] | Menos navegação para escolher período e localizar registros; não importar conceitos de cartões, parcelas ou pendência sem regras próprias. |
| App Sebrae | Página institucional apresenta Android/iOS, registro de entradas/saídas no fluxo de caixa e serviços do DAS MEI.[8] | Preservar o foco em registro e entendimento do negócio. Serviços de emissão/pagamento não equivalem ao lembrete local do NotaMei nem são integração simples. |

**Acesso:** README de Cashew/Ivy recuperados diretamente. O HTML da ajuda Organizze retornou 403; o conteúdo foi obtido pela API pública oficial do próprio Help Center. No Sebrae, o HTML é uma aplicação: foram extraídos os textos dos componentes do JSON `initialData` entregue pela página oficial, sem executar código externo. As fontes foram registradas com evidências; não se alegou navegação/ensaio dos apps. Uma URL regional inicialmente localizada falhou por TLS e não embasa as conclusões.

## O que o NotaMei já cobre

Entrada/saída manual, âmbito Negócio/Pessoal, painel e Histórico mensais, filtros de âmbito/tipo, lançamento em sequência, retirada vinculada, anual comercial, lembrete pessoal do DAS e relatórios CSV/PDF. Não propor esses recursos como se ainda faltassem. Rastreio: `lib/finance/`, `lib/annual/`, `lib/das/`, `lib/export/`, `lib/data/entry_totals.dart` e [catálogo de requisitos/RN](../hermes/REQUISITOS-ARQUITETURA.md).

## Como classificar esforço

- **Baixo:** UI/filtro local ou texto; sem nova persistência, permissão, servidor ou dependência; testes limitados a um fluxo.
- **Baixo–médio:** reutiliza dados existentes, mas exige decisões de cálculo/acessibilidade e testes combinados.
- **Médio:** estado persistente/regra nova, integração entre telas ou mudança relevante em dados/notificações.
- **Alto:** restauração/migração/conflitos, serviço externo, câmera/documentos, sincronização ou múltiplas regras financeiras.

Não é prazo e não pressupõe habilidade individual. “Sem migração prevista” vale para o recorte mínimo descrito, não para qualquer ampliação futura.

## Melhorias candidatas prioritárias

### H01 — busca textual no Histórico — baixo

**Hipótese de utilidade:** localizar uma compra/receita pela categoria ou observação, sem percorrer todo o mês. Cashew documenta pesquisa/filtros; o NotaMei atualmente filtra mês/âmbito/tipo e ordena por data, sem campo de busca.[1] Rastreio local: `lib/finance/entry_history_screen.dart`.

**Recorte:** busca apenas nos registros do mês e filtros ativos; definir se ignora caixa/acentos. Não anunciar busca global se ela só procura no mês. Sem nova coluna/biblioteca/servidor; não registrar consultas em logs.

**Aceite:** termo vazio conserva lista; busca combina com Negócio/Pessoal/Todos e tipo; limpar termo não apaga os filtros; nenhum registro/retirada é alterado; resultado vazio é legível; texto ampliado não quebra a tela. Proposta posterior para Matheus, após T01 e aprovação.

### H02 — atalhos de período na exportação — baixo

**Hipótese:** reduzir toques para selecionar o dia/mês atual. Organizze documenta seleções prontas de período.[9]

**Recorte:** botões Hoje/Mês atual usando os períodos já existentes em `ExportSelection`; conservar âmbito, tipo e opção de observações. CSV/PDF continuam iguais. “Últimos 7 dias” não é a mesma coisa que semana segunda–domingo e fica fora desta primeira fatia.

**Aceite:** ano/mês/data corretos inclusive na virada; prévia/arquivo coincidem; snapshot/bloqueio durante saída permanecem; ambos os formatos testados. Sem migração/novo pacote. Alinhar dono único de `export_screen.dart` com Pedro.

### H03 — lista de despesas por categoria — baixo–médio

**Hipótese:** mostrar onde se concentram as saídas comerciais, sem chamar a diferença de lucro. Relatório por categorias aparece na ajuda Organizze.[9]

**Recorte:** lista textual do mês e âmbito escolhido, com totais exatos de despesas **comuns**, excluindo retiradas, sem gráfico/biblioteca nova. Definir tratamento de nomes iguais e ordenação. Reusar as regras financeiras existentes; totais `BigInt`, não `double`.

**Aceite:** categorias somam exatamente as despesas comuns do mesmo recorte; retirada não vira custo; pessoal não vaza para Negócio; vazio/overflow são explícitos; rótulos não certificam lucro/faturamento. Sem migração prevista. Dono e tela definidos após aprovação; revisão financeira de Pedro obrigatória.

### H04 — seletor de ano no acompanhamento anual — baixo–médio

**Hipótese:** consultar anos já registrados sem usar exportação. É evolução interna, não funcionalidade atribuída a concorrente nesta pesquisa.

**Recorte:** o cálculo `recordedAnnualIncome` já recebe ano; a composição atual oferece o ano corrente. Acrescentar escolha de ano sem saldo inicial, receita declarada ou limite fiscal.

**Aceite:** ano/rótulos e 12 meses coerentes; futuras/retroativas consideradas pela data informada; somente entradas comerciais comuns; retiradas excluídas; ausência de registro não é mês sem movimento. Sem migração. Conciliar com a decisão de alcance das datas e reservar `notamei_app.dart` para uma pessoa.

### H05 — escolher ordenação no Histórico — baixo

**Hipótese:** facilitar localizar registros antigos ou de maior valor. Evolução interna da lista, sem alegar presença específica em concorrente.

**Recorte:** data decrescente **já existe**; adicionar opção crescente e/ou valor sem mudar filtros ou persistência. Definir desempate estável; não trocar sinal do valor de uma saída para ordenar.

**Aceite:** nenhuma linha some/duplica, dados e totais preservados, cancelamento/edição continuam corretos. Sem migração. H01 e H05 mexem na mesma tela: integrar sequencialmente, não em paralelo.

### H06 — ajuda curta e offline sobre os indicadores — baixo

**Hipótese:** esclarecer Negócio/Pessoal, retirada, balanço, anual, DAS e relatório versus backup. Evolução de clareza do NotaMei, não importação de conteúdo comercial.

**Recorte:** tela/glossário curto a partir das RN já aprovadas, acionável em Ajustes; sem chatbot, API ou orientação fiscal individual. Luchie pode preparar texto/roteiro e, após aprovação, contribuir com o patch acompanhado de teste.

**Aceite:** textos corretos e acessíveis, sem promessa de lucro/regularidade/entrega; funciona offline e não pede dados/permissões; links internos e navegação conferidos. Sem migração/dependência.

## Recursos que parecem simples, mas não priorizaria como tarefa rápida

| Recurso | Complexidade no recorte do NotaMei | Motivo |
| --- | --- | --- |
| Categorias próprias / favoritos persistentes | Média | Regras de edição/exclusão, histórico, âmbito e opções reservadas; categorias predefinidas já existem. |
| Novo lançamento semelhante | Média | Precisa criar novo ID/rascunho e confirmação sem sobrescrever original; não clonar ponta de retirada. |
| Orçamento/meta mensal | Média | Configuração persistente e semântica de consumo/período; não confundir meta pessoal com limite legal. |
| Recorrências, contas a pagar/receber e fiado | Média–alta | Futuro versus realizado, liquidação parcial, cancelamento, atraso, lembretes e totais novos. |
| Backup com restauração / importação CSV | Alta | Integridade, versão, migração, conflito, duplicidade, privacidade e falha parcial; relatório atual não resolve isso. |
| Pix/banco, DAS automático, sincronização | Alta | Serviços externos, segurança, consentimento e regras de domínio; não são “só uma tela”. |
| QR de compra completa, OCR, leitor fiscal | Alta | Obter/validar itens, origem e formatos; código lido não contém necessariamente a compra toda. |
| IA no app e versão Lite | Investigação própria | Utilidade, recursos, manutenção, privacidade e validação; Lite continua para depois do lançamento. |

## Seleção recomendada

Para um próximo ciclo pequeno, **começar por H01 e H06; H02 em seguida**. H03 e H04 agregam análise, mas exigem fechar critérios. H05 pode entrar na mesma janela sequencial do Histórico, sem inflar o escopo da busca. Essa ordem é proposta, não compromisso de prazo ou implementação autorizada.

Antes disso, concluir os gates de qualidade do [checklist](CHECKLIST-EQUIPE.md): ensaiar o já implementado, alinhar documentação e decidir os caminhos de falha. Não tentar reproduzir todo o Cashew, Organizze ou App Sebrae.

## Sources

[1] https://github.com/jameskokoska/Cashew/blob/main/README.md
[5] https://github.com/Ivy-Apps/ivy-wallet
[8] https://sebrae.com.br/subsites/aplicativo-sebrae
[9] https://ajuda.organizze.com.br/hc/pt-br/articles/360036370073-Android-Relat%C3%B3rios-Filtros-dos-relat%C3%B3rios
[10] https://ajuda.organizze.com.br/hc/pt-br/articles/6493515699987-Android-Lan%C3%A7amentos-Filtrar-lan%C3%A7amentos
