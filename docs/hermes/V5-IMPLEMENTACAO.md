# V5 Editorial B — implementação Flutter

## Recorte entregue

V5 identifica a família visual aprovada, não uma versão 5.0 do produto. A versão do APK permanece `1.0.0+1`. O redesenho foi implementado em Flutter nativo, sem importar páginas HTML do Stitch como interface executável.

- **Tema e marca:** papel quente, tinta noturna, superfícies planas com bordas; entradas verdes e saídas vermelhas, acompanhadas de sinal e rótulo. Inter e Playfair Display são arquivos locais incluídos no APK, junto às licenças OFL. O monograma N existente foi preservado e recolorido tanto no asset interno quanto nas cinco densidades do launcher Android: fundo tinta `#1E1735`, letra papel `#FAF8F5` e detalhes verdes `#28724B`. A recoloração mantém dimensões, posições dos pixels e canal alpha; não redesenha a marca.
- **Início:** seleção de mês com setas, filtros Negócio/Pessoal/Todos, resumo escuro, ação de novo lançamento no fluxo e folha de registros com divisórias. Não há FAB cobrindo o último registro.
- **Lançamento e edição:** hierarquia editorial, seleção de tipo com cor semântica, âmbito independente, validação inline e ações acessíveis com teclado. FB01 mantém a sequência após sucesso, limpa só valor/observação e retorna o foco ao valor. Controles ficam bloqueados durante gravação.
- **Histórico:** filtros de âmbito e tipo separados, folha de registros, edição e exclusão confirmada. “Todos” no grupo Âmbito não apaga o filtro de tipo; desmarcar Entradas/Saídas remove a restrição de tipo.
- **Ano:** receitas comerciais informadas, doze meses, legenda dos travessões e aviso de histórico parcial. Não indica validação fiscal ou ausência comprovada de movimento.
- **Primeiro uso/tour:** boas-vindas, três etapas com progresso, retorno, pular e conclusão; opção de rever em Ajustes sem apagar dados. Exemplos são fictícios e não persistidos como lançamentos.
- **Ajustes/DAS:** composição editorial com estado do lembrete, dia/horário pessoais e feedback de permissão/falha. Não confunde lembrete com vencimento ou pagamento.

## Invariantes preservados

Não houve mudança em `lib/data/`, `lib/core/`, no serviço de lembretes ou no gateway de notificações. Cálculos continuam em centavos inteiros, registros em SQLite e preferências locais. Não foram acrescentados contas, backend, integração bancária, exportação, IA, novas categorias ou modo escuro.

## Validação executada

- `flutter test`: **95 testes aprovados** após a correção do ícone. O teste adicional decodifica as cinco densidades, verifica a paleta V5 e exige igualdade entre o bitmap interno e o launcher de maior resolução.
- O APK reconstruído teve os seis PNGs (cinco densidades e marca interna) extraídos e comparados byte a byte com os assets atualizados. Esta reconstrução do ícone não foi instalada no aparelho físico.
- `flutter analyze`: **No issues found**.
- `flutter build apk --debug`: concluído.
- `git diff --check`: sem erros.
- Testes de widget incluem largura de 390 px, texto ampliado até 2x em telas específicas, teclado simulado, sequência, falhas/retry, foco, filtros, edição/exclusão, tour e estados do DAS. Isso não equivale a acessibilidade universal comprovada.
- Revisão independente identificou um bloqueador no filtro “Todos”; corrigido com teste RED/GREEN e releitura independente aprovada. A implementação do Histórico ainda materializa as linhas do mês: medir e considerar lista lazy para históricos extensos é uma recomendação não bloqueadora.
- APK final instalado no emulador Android API 36; hash do pacote instalado corresponde ao artefato gerado. Rotas principais, filtros e fim da lista foram exercitados. As três etapas do tour e a conclusão foram percorridas; formulário/validação e DAS foram inspecionados visualmente.
- Os três registros preexistentes do emulador permaneceram idênticos antes/depois da atualização e navegação. Não houve limpeza geral da base.

## Limites desta rodada

Não foi realizado novo teste no A17 físico nem teste de entrega futura de notificação. O APK usa assinatura debug e não é uma distribuição pública pronta. A aparência foi adaptada criticamente das referências: os mockups não substituem requisitos ou regras reais. Pendem avaliação do responsável no aparelho e eventual refinamento visual.

As capturas, logs, APK e hashes ficam fora do repositório, no diretório local de validação V5. Nenhum commit, merge ou push foi realizado nesta rodada. Alterações locais anteriores de FB01/FB02 e documentação foram preservadas.
