# T03 — Avaliação de acessibilidade

## Objetivo
Avaliar rótulos, foco, mensagens de erro e comportamento do formulário de lançamentos do NotaMei.

## Ambiente
- Sistema operacional: Windows 11
- Flutter: 3.47.9
- Teste: `test/finance/entry_sequence_test.dart`

## Evidências iniciais

Foi executada a suíte de testes de sequência de lançamentos.

Resultado observado:
- 11 testes passaram.
- 1 teste falhou.

Teste com falha:
`390px e texto 2x preservam erro, sequência e foco acima do teclado`

Ocorrências registradas:
- Overflow vertical de 17 pixels.
- Aviso de toque que não atingiu o elemento esperado.
- Categoria esperada: `Mercadorias / Matéria-prima`.
- Categoria encontrada: `Vendas`.

## Análise preliminar
A falha pode estar relacionada à interação com a opção de despesa sob condições simuladas de texto ampliado e teclado aberto.

Ainda não foi confirmado se a causa está no layout do aplicativo ou na implementação do teste.

## Verificações pendentes
- Avaliar os anúncios dos campos Valor e Observação com TalkBack.
- Verificar navegação por foco e mensagens de erro.
- Confirmar o comportamento de salvar e cancelar com teclado aberto e texto ampliado.

## Encaminhamento
Solicitar revisão de Raphael antes de realizar alterações no formulário ou nos testes.

## Estado
Avaliação inicial documentada. T03 ainda não concluída.