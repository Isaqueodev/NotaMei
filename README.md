# NotaMei

**Organização financeira simples para o microempreendedor individual (MEI).**

O NotaMei é um aplicativo Android desenvolvido em Flutter para ajudar a registrar, consultar e acompanhar movimentações financeiras informadas pela própria pessoa. É um projeto acadêmico extensionista em estágio de **MVP** (primeira versão funcional): prioriza lançamentos manuais, separação entre negócio e vida pessoal e uma leitura clara do histórico, sem substituir controles contábeis ou canais oficiais.

> **Em uma frase:** anote entradas e saídas, veja o balanço mensal do negócio e configure um lembrete pessoal para conferir o DAS.

## O que é possível fazer

| Área | Funcionalidade |
| --- | --- |
| Primeiro uso | Escolher entre um tour opcional e começar direto; rever o tour em **Ajustes**. |
| Lançamentos | Registrar **entrada** ou **saída**, valor em reais, data, categoria e observação opcional; classificar manualmente como **Negócio** ou **Pessoal**. Editar e excluir registros. |
| Início | Consultar entradas, saídas, balanço e lançamentos recentes do **negócio** no mês selecionado. O balanço é entradas menos saídas registradas, não o saldo de uma conta bancária. |
| Histórico | Navegar por mês e filtrar os registros por Negócio/Pessoal e Entrada/Saída. |
| Ano | Ver a soma por mês e o total das **entradas do negócio informadas** no ano corrente. Meses sem registro não são tratados como meses sem movimento. |
| Ajustes | Ativar ou desativar um lembrete local relacionado ao DAS, escolhendo dia do mês e horário. Rever o tour. |

### Exemplo de uso

1. Ao abrir o aplicativo pela primeira vez, escolha **Ver como funciona** ou **Começar sem tour**.
2. Em **Início**, toque em **Novo Lançamento** e registre, por exemplo, uma venda como entrada do **Negócio**. Use exemplos fictícios ao demonstrar o app para outra pessoa.
3. Registre uma despesa do negócio ou um gasto **Pessoal**; a classificação pessoal não entra no balanço do negócio nem no total anual de entradas comerciais.
4. Consulte **Histórico** para localizar ou corrigir um lançamento e **Ano** para acompanhar o que foi informado.
5. Se desejar, abra **Ajustes → Configurar lembrete**, escolha dia e horário e ative o aviso. Confira sempre a situação do DAS nos canais oficiais.

## Uso no celular, sem cabo e sem internet

Depois que o APK é instalado, **o cabo USB pode ser desconectado**: ele foi necessário para instalação e depuração, não para abrir ou usar o aplicativo. Os lançamentos e configurações ficam no próprio aparelho; as funções centrais de registro e consulta não exigem conexão com a internet nem conta no NotaMei. Encerrar e reabrir o app normalmente não apaga os lançamentos.

**Cuide dos dados:** limpar os dados do aplicativo ou desinstalá-lo pode apagar os registros locais. O NotaMei ainda não oferece exportação, restauração, conta ou sincronização próprias. Eventuais cópias feitas pelo sistema Android dependem das configurações do aparelho e **não devem ser presumidas como backup garantido**.

Os lembretes dependem de permissão de notificações e das políticas de agendamento e economia de bateria do Android. O app solicita a permissão ao ativar o lembrete; não há garantia de entrega pontual. Para dias 29, 30 ou 31 em meses mais curtos, o aviso é ajustado para o último dia do mês. Há uma janela de agendamentos futuros renovada ao abrir o app.

## Limites importantes

- **Não é um sistema bancário:** não acessa contas, extratos ou Pix; nenhum valor é importado automaticamente.
- **Não apura obrigações fiscais:** o resumo anual considera apenas entradas do negócio que você registrou. Não certifica faturamento fiscal, lucro, limite legal, regularidade ou meses sem movimento.
- **Não consulta nem paga o DAS:** o dia do lembrete é escolhido por você, **não** é um vencimento legal calculado pelo app. O aviso não confirma emissão, pagamento ou quitação. Consulte os canais oficiais e, quando necessário, orientação contábil.
- **Não é uma versão de distribuição:** o APK de depuração serve para testes e apresentação. Uma distribuição pública requer preparação e assinatura próprias, além de validações adicionais.

## Tecnologia e desenvolvimento

O aplicativo é desenvolvido em **Flutter/Dart** para Android. Lançamentos são persistidos em SQLite (`sqflite`); preferências de primeiro uso e lembrete usam `shared_preferences`; o agendamento local usa `flutter_local_notifications`. Não há backend ou sincronização implementados nesta versão.

Estrutura principal:

```text
lib/app/         Inicialização visual e navegação
lib/onboarding/  Primeiro uso e tour
lib/finance/     Início, formulário e histórico
lib/annual/      Acompanhamento anual descritivo
lib/das/         Configuração e agendamento de lembretes
lib/data/        Modelo e persistência dos lançamentos
test/            Testes automatizados por área
```

Para desenvolver localmente, instale o Flutter SDK e o Android SDK, conecte um dispositivo Android ou prepare um emulador e, na raiz do projeto, execute:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Para gerar um **APK de depuração** instalável sem manter o cabo conectado:

```sh
flutter build apk --debug
```

O arquivo gerado fica em `build/app/outputs/flutter-apk/app-debug.apk`. Se for instalar manualmente com ADB, use `adb install -r build/app/outputs/flutter-apk/app-debug.apk` com a depuração USB autorizada no dispositivo. Antes de apresentar, abra o aplicativo no próprio telefone e confira o fluxo desejado; depois da instalação, a execução normal não depende de ADB.

## Estado do projeto

Esta versão cobre o fluxo local de apresentação e uso manual. Exportação/backup próprios, sincronização, integrações externas e regras fiscais automáticas **não estão implementados**. Documentos de pesquisa individual e referências visuais de terceiros são materiais locais ignorados pelo Git e não fazem parte da distribuição do aplicativo.

Para continuar o desenvolvimento com o Hermes Agent em outro computador, consulte [as instruções de migração para Windows](docs/hermes/IMPORTAR-WINDOWS.md). Elas transferem apenas conhecimento revisado e não incluem dados de pesquisa, conversas ou credenciais.
