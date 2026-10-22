---
name: notamei-validacao-android
description: "Valide fluxos Android do NotaMei sem apagar dados."
license: MIT
metadata:
  author: "Equipe NotaMei, Hermes Agent"
  version: "0.1.0"
---

# NotaMei — qualidade e Android

## Quando usar

Ao planejar/executar testes, reproduzir falha ou preparar evidência de demonstração. Foco inicial proposto a Raphael Max; não presume experiência, aparelho ou SDK disponíveis.

## Pré-requisitos

Leia [AGENTS.md](../../../AGENTS.md), o contrato de tarefa e o roteiro aprovado. Registrar resultados não autoriza instalar APK, operar aparelho ou criar dados: obtenha consentimento. Em chat sem ferramentas, forneça o roteiro para execução humana e marque como não executado.

## Procedimento

1. Identifique commit/candidato, origem do APK, versão, assinatura e ambiente. Resultados de outra versão não aprovam esta. Preserve bancos e preferências reais.
2. Separe quatro evidências: teste automatizado, build, instalação e fluxo nativo. Rode analyze/test somente se o ambiente permitir; guarde comandos/saídas reais.
3. Prefira emulador/aparelho de teste com dados fictícios. Se usar ADB, confira conexão/autorização/serial e pacote em primeiro plano; pare em bloqueio, outro app ou confirmação não autorizada.
4. Exercite cadastro/edição/exclusão/cancelamento, sequência, filtros independentes, reabertura, retirada completa e anual sem internas. Compare os valores com casos já existentes, não com aritmética inventada pela IA.
5. Em CSV/PDF, confira padrão de observações desligadas, seleção, totais, salvar/reabrir, cancelar e compartilhar. Conferir arquivo recebido não equivale a provar envio a destinatário final.
6. Em DAS, diferencie ativação, desativação, refresh, permissão negada e falha parcial. Registre agendamento e entrega futura separadamente. Definir política/alterar serviço exige tarefa específica e testes próprios.
7. Verifique texto ampliado, teclado, scroll e TalkBack quando disponíveis. Adaptação em widget não certifica acessibilidade universal.
8. Remova apenas fixtures autorizadas/identificadas e compare o estado final com o inicial. Entregue matriz com cenário, resultado observado, evidência sanitizada e pendências.

## Armadilhas

- Não limpar/desinstalar, fazer downgrade ou substituir assinatura para forçar aprovação.
- Não testar migração usando banco real: simule v1→v2 em ambiente dedicado e preserve a base sintética inicial.
- Não publicar APK, banco, logs privados, teclados pessoais ou notificações nas evidências do Git.
- Não recomendar desativar Play Protect. Investigue alertas exatos com Pedro.
- Snapshot/mock não comprova funcionamento nativo; exportação não restaura o banco.

## Verificação

A matriz precisa indicar versão/ambiente e o que foi realmente executado. Falha deve conter passos mínimos e impacto, sem culpar modelo/plugin por suposição. Sem dispositivo, a validação nativa permanece pendente, mesmo com testes verdes.
