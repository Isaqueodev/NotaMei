# ADR-002 — Persistir lançamentos em SQLite local com transações

- **Data do registro:** 2026-11-11.
- **Status:** decisão observada em `9076f3d`; registro retrospectivo, ratificação pendente.
- **Data da decisão original:** não estabelecida; nenhuma migração foi executada por este documento.
- **Relação anterior:** ARQ-02, mantida no [C4](../C4-NOTAMEI.md).

## Contexto

RF01/RF04 e FB08 dependem de persistir alterações e recuperar registros. RN10–RN13 exigem representar uma retirada como operação com duas pontas vinculadas, sem publicar par incompleto. RNF02 trata de integridade e RNF10 de preservação na atualização; RNF09 propõe uma medição de desempenho ainda sem aprovação ou execução.

## Alternativas consideradas

### A — SQLite local por repositório, com transações (observada)

**A favor:** oferece um ponto de coordenação para escrita e leitura do snapshot na mesma transação, e um caminho explícito de versão/migração do esquema.

**Contra:** exige manutenção de migrações e cuidado com fila, releitura, validação e uso de memória; não resolve backup/restauração ou sincronização.

### B — Arquivo de registros serializados, sem banco relacional

**A favor:** formato potencialmente simples de inspecionar e transportar em um recorte pequeno, se isso fosse um requisito aprovado.

**Contra:** exigiria projetar equivalentes de atualização atômica, concorrência, consultas e evolução de formato; uma serialização simples não constitui a integridade de duas pontas exigida pelo produto.

Comparação técnica retrospectiva; não representa histórico comprovado de escolha dessas alternativas.

## Decisão documentada

Lançamentos ficam em SQLite local, acessados por `EntryRepository`. `upsert`, `saveWithdrawal` e `remove` passam pela fila de mutações. O snapshot resultante é lido dentro da transação; `_entries` e ouvintes são atualizados depois do retorno bem-sucedido. A retirada usa IDs determinísticos e vínculo explícito; colisões com registro comum são recusadas.

O esquema observado é **2**. A migração de v1 acrescenta `withdrawal_id TEXT`, sem inferir vínculo nos registros antigos. Preferências são outro armazenamento local. Não há downgrade de dados implementado.

## Consequências positivas

- Escrita de ambas as pontas e releitura pertencem à mesma transação no fluxo observado.
- Snapshot publicado após commit reduz o risco de interface apresentar uma gravação revertida como concluída.
- Migração aditiva evita reclassificar dados antigos por categoria/valor.

## Consequências negativas

- O repositório mantém snapshot do histórico e serializa mutações; crescimento exige medição, não promessa de escala.
- Falhas físicas, perda da base e notificações de interface após commit não são cobertas por uma garantia universal de recuperação.
- Voltar o código não restaura dados e pode tornar um APK antigo incompatível com a base migrada; ensaios devem usar fixtures, nunca limpeza de dados reais.

## Evidências e verificação

- Código: [`EntryRepository`](../../../lib/data/entry_repository.dart), [`EntryRecord`](../../../lib/data/entry_record.dart).
- Cobertura existente: [`withdrawal_test.dart`](../../../test/data/withdrawal_test.dart), [`entry_repository_test.dart`](../../../test/data/entry_repository_test.dart).
- Vistas: C2, C3/REPO, código e sequência no [C4](../C4-NOTAMEI.md).
- Plano: RNF02/RNF09/RNF10 na [matriz](../RASTREABILIDADE.md). Esta revisão não executou testes Flutter, benchmark, migração ou instalação no aparelho.
