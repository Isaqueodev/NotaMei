# Decisões de arquitetura — NotaMei

## Estado e origem dos registros

**Registro documental:** 2026-11-11. **Base examinada:** `9076f3d`. Estes ADRs foram reconstruídos a partir do código e da documentação existentes: não são atas históricas nem prova de que as alternativas foram debatidas pela equipe na época. A data é a do registro, não a da decisão original, que não foi estabelecida nesta revisão.

**Status comum:** decisão observada na implementação; registro retrospectivo com ratificação pela equipe pendente. Não usar “aceita em 2026-11-11” nem tratar esta revisão documental como aprovação de mudança técnica. As alternativas são uma comparação técnica para explicar o estado atual, não uma cronologia inventada.

| ADR | Decisão observada | Rastreio anterior preservado | Qualidade relacionada |
| --- | --- | --- | --- |
| [ADR-001](ADR-001-NUCLEO-LOCAL.md) | Manter núcleo manual local, sem backend obrigatório | ARQ-01, ARQ-07 | RNF01, RNF04, RNF06, RNF08 |
| [ADR-002](ADR-002-SQLITE-TRANSACOES.md) | Persistir lançamentos em SQLite local, com transações e migração aditiva | ARQ-02 | RNF02, RNF09, RNF10 |
| [ADR-003](ADR-003-CENTAVOS-EXATOS.md) | Representar dinheiro em centavos inteiros e centralizar os totais exatos | ARQ-03 | RNF03, RNF07 |

As entradas ARQ-04 a ARQ-06 permanecem registradas no [C4](../C4-NOTAMEI.md): acesso direto ao repositório, gateway DAS e estado de filtro não persistido. Não foram convertidas artificialmente em ADRs para cumprir quantidade acadêmica. RNF05 se relaciona à interface/semântica no C3 e ao protocolo de validação, não exige inventar uma decisão histórica adicional.

## Convenção para novos registros

1. Usar identificador estável, título como decisão, data real de registro e status explícito.
2. Explicar o problema e apontar RF/RNF/RN que motivam a escolha.
3. Comparar pelo menos duas alternativas reais, com vantagens e custos.
4. Registrar decisão, consequências positivas e negativas, evidências e limitações.
5. Quando substituir uma decisão, ligar os dois registros sem apagar o anterior; mudanças de produto/código exigem aprovação própria.

A [matriz de rastreabilidade](../RASTREABILIDADE.md) distingue alvo de qualidade, presença no código, cobertura de testes e execução comprovada. Documentar uma decisão não aprova uma meta de desempenho nem comprova conformidade fiscal.
