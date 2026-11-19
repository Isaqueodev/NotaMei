# Criar backup nos Ajustes

## Disponível neste incremento

`Ajustes → Criar backup` abre `BackupCreationScreen`, ligada ao serviço de criação
já implementado. A [importação aditiva](IMPORTACAO.md) também está integrada em Ajustes, com abertura, prévia e confirmação; não substitui o histórico nem restaura configurações.

O aplicativo não cria cópias em segundo plano e não pede senha nova por inferência.
O JSON é legível, sem senha/criptografia/autenticação, e inclui todas as observações.
Nenhum dado, preferência, schema, dependência ou permissão é alterado pela criação.

## Fluxo

1. Abra **Ajustes → Criar backup**.
2. Leia os avisos: todo o histórico de Negócio/Pessoal, sem filtros; registros,
   observações e pares de retirada; dados legíveis; importação não substitui nem apaga registros.
3. Marque **Entendi que a cópia inclui todos os dados e observações, sem senha.**
   A ação fica desabilitada até essa ciência. A marcação não é persistida e reinicia
   desmarcada ao abrir uma nova tela.
4. Toque em **Escolher local e salvar** e escolha o destino no seletor do sistema.
5. Aguarde o resultado e confira o arquivo no destino escolhido. Cancelar não é
   informado como sucesso. Confira a cópia antes de depender dela e use a importação em Ajustes para adicionar registros. Não limpe dados para contornar conflitos; configurações não são restauradas.

São mantidos os limites do [formato v1](FORMATO-V1.md): 10 MiB e 10.000 linhas,
contando cada ponta da retirada. Não existe truncamento ou seleção parcial nesta tela.
CSV/PDF continuam relatórios separados; não se tornam restauráveis.

## Estado da operação e mensagens

- A tela reutiliza uma instância de `BackupCreationService`. O bloqueio começa
  antes da preparação e dura até o retorno do seletor, com indicador de progresso.
- Botão e ciência ficam desabilitados durante a operação; o retorno da rota é
  bloqueado por `PopScope`. Duplo toque antes do próximo frame também é ignorado.
- O serviço captura o histórico na fila de mutações e mantém os bytes enviados
  congelados, mesmo se uma operação anterior ainda estava em processamento.
- Resultados são mensagens na própria tela, com região semântica viva, não uma
  confirmação automática de integridade. A mensagem de sucesso diz **O Android
  informou que o arquivo foi salvo** e orienta conferir o destino.
- Cancelamento permite nova tentativa. Erros de preparação e salvamento não
  mostram a exceção original, notas, IDs ou caminhos privados. Falha de salvamento
  não garante ausência de um documento parcial no provedor.
- Resultados inesperados de compartilhamento não são tratados como backup salvo.
- Ao finalizar, o bloqueio é liberado. Se a tela tiver sido desmontada externamente,
  a conclusão não tenta atualizar seu estado descartado.

A tela não mostra uma prévia de conteúdo baseada em `prepare()` para depois salvar
um snapshot diferente. Apenas explica o escopo completo; a [inspeção limitada e seus
metadados](LEITURA-PREVIA.md) são usados na tela separada de [importação](IMPORTACAO.md).

## Validação e limites de evidência

Os testes de widget exercitam ciência obrigatória, progresso, duplo toque, retorno
bloqueado, cancelamento/falhas/retentativas, mensagens seguras e desmontagem. O
controle em **390 × 844 e texto 2x**, com Roboto local carregada, verifica alcance
dos avisos e ações nos temas claro/escuro. Isso não substitui TalkBack nativo.

O teste de integração usa a navegação real de `NotaMeiApp`, SQLite FFI em memória
e o serviço/gateway reais, com **canal de arquivo simulado**. Compara todos os
campos do JSON com o histórico de meses/anos e âmbitos distintos, incluindo retirada,
e verifica que registros e preferências não mudam. Reabrir a tela reinicia a ciência.

```sh
flutter test --no-pub test/backup
flutter analyze --no-pub
flutter build apk --debug --no-pub
```

Ainda falta aceite do seletor Android, do arquivo no destino real e dos recursos
assistivos no aparelho. Build e testes de widget não certificam essas etapas.
A implementação não atualiza automaticamente um APK já instalado ou o arquivo
existente em Downloads.

## Pendências separadas

- Substituição integral, senha e restauração de preferências não foram implementadas; a importação é somente aditiva.
- Aceite Android de criação, cancelamento, erros e persistência do documento real.
