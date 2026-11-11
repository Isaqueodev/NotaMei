# ADR-001 — Manter o núcleo financeiro manual e local

- **Data do registro:** 2026-11-11.
- **Status:** decisão observada em `9076f3d`; registro retrospectivo, ratificação pendente.
- **Data da decisão original:** não estabelecida. Não há nova mudança de código neste ADR.
- **Relação anterior:** ARQ-01 e ARQ-07, preservadas no [C4](../C4-NOTAMEI.md).

## Contexto

RF01–RF04 e RF07 atendem cadastro/consulta de registros pessoais do aparelho; RN08 impede interpretar histórico parcial como saldo bancário. RNF01 pretende operação sem rede; RNF04 limita a saída de dados; RNF06 delimita Android como plataforma do produto; RNF08 separa falha do lembrete de acesso financeiro. A arquitetura consultada não possui conta, API HTTP de negócio, servidor ou sincronização.

## Alternativas consideradas

### A — Núcleo local sem backend obrigatório (observada)

**A favor:** mantém o caminho de cadastro/consulta no aparelho, sem depender de conta no produto; permite delimitar saída financeira às ações de exportação/compartilhamento.

**Contra:** não resolve recuperação após perda do aparelho nem acesso em múltiplos dispositivos; armazenamento local não protege, por si, contra acesso físico ou políticas de backup do sistema.

### B — Núcleo dependente de serviço remoto

**A favor:** permitiria projetar conta, centralização e recuperação entre dispositivos, se esses requisitos fossem aprovados e implementados.

**Contra:** exigiria operação de serviço, autenticação, política de dados, custos, tratamento de indisponibilidade e solução explícita para uso sem rede. Não é componente existente do NotaMei.

Estas alternativas explicam o estado observado; não afirmam uma deliberação histórica comprovada.

## Decisão documentada

Descrever o núcleo como aplicativo Android local, com SQLite/preferências e pontes nativas. Cadastro/consulta não dependem de backend do produto. Relatórios são saídas voluntárias; uma aplicação destinatária pode ter rede/política própria fora do controle do NotaMei. O lembrete é serviço local sujeito ao Android, não consulta fiscal nem garantia de entrega.

**Não decidido aqui:** criptografia própria, backup/restauração, sincronização, API acadêmica ou versão iOS. A exigência cliente-servidor de outro exercício não altera a arquitetura deste produto.

## Consequências positivas

- Fronteiras atuais simples e verificáveis nos níveis C1/C2.
- Possibilidade de testar lógica e widgets sem possuir celular Android; isso não certifica os fluxos nativos.
- Menor escopo de infraestrutura própria; nenhum segredo de serviço deve ser criado apenas para preencher a documentação.

## Consequências negativas

- Perda/limpeza/desinstalação podem comprometer o histórico; CSV/PDF não restauram a base.
- Arquivos exportados e políticas do sistema operacional ampliam a superfície de exposição.
- Uso offline e notificações precisam de ensaios identificados; não há certificação de compatibilidade universal.

## Evidências e verificação

- Código: [`main.dart`](../../../lib/main.dart), [`StartupScreen`](../../../lib/app/startup_screen.dart), [`EntryRepository`](../../../lib/data/entry_repository.dart), [`ExportGateway`](../../../lib/export/export_gateway.dart).
- Diagramas: C1, C2 e implantação em [C4-NOTAMEI.md](../C4-NOTAMEI.md).
- Plano: RNF01/RNF04/RNF06/RNF08 e [matriz](../RASTREABILIDADE.md); testes automatizados existentes não foram novamente executados nesta revisão documental.
