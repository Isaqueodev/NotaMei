# NotaMei

**Organização financeira simples para o microempreendedor individual (MEI).**

O NotaMei é um aplicativo Android desenvolvido em Flutter para ajudar a registrar, consultar e acompanhar movimentações financeiras informadas pela própria pessoa. É um projeto acadêmico extensionista em estágio de **MVP** (primeira versão funcional): prioriza lançamentos manuais, separação entre negócio e vida pessoal e uma leitura clara do histórico, sem substituir controles contábeis ou canais oficiais.

> **Em uma frase:** anote entradas e saídas, veja o balanço mensal do negócio e configure um lembrete pessoal para conferir o DAS.

## O que é possível fazer

| Área | Funcionalidade |
| --- | --- |
| Primeiro uso | Escolher entre um tour opcional e começar direto; rever o tour em **Ajustes**. |
| Lançamentos | Registrar **entrada** ou **saída**, valor em reais, data, categoria e observação opcional; classificar manualmente como **Negócio** ou **Pessoal**. Usar **Salvar e adicionar outro** para continuar no formulário, ou o salvamento normal para voltar. Editar e excluir registros. |
| Início | Consultar entradas, saídas, balanço e lançamentos recentes no mês selecionado, filtrando **Negócio**, **Pessoal** ou **Todos**. O padrão é Negócio; Todos identifica explicitamente a soma geral dos dois âmbitos. O balanço considera também retiradas enviadas/recebidas por âmbito, sem duplicar internas em Todos; não é saldo bancário. |
| Pagar-me | Registrar uma **Retirada do titular**: saída do Negócio e entrada no Pessoal vinculadas, com edição/exclusão conjunta. Não duplica entradas/saídas gerais nem receita anual. É registro manual, sem transferência real ou classificação fiscal automática. |
| Histórico | Navegar por mês e filtrar os registros por Negócio/Pessoal e Entrada/Saída. |
| Ano | Ver a soma por mês e o total das **entradas do negócio informadas** no ano corrente. Meses sem registro não são tratados como meses sem movimento. |
| Ajustes | Ativar ou desativar um lembrete local relacionado ao DAS, escolhendo dia do mês e horário. Rever o tour. Exportar relatórios CSV ou PDF por período e filtros, para salvar localmente ou compartilhar. |

### Exemplo de uso

1. Ao abrir o aplicativo pela primeira vez, escolha **Ver como funciona** ou **Começar sem tour**.
2. Em **Início**, toque em **Novo Lançamento** e registre, por exemplo, uma venda como entrada do **Negócio**. Use exemplos fictícios ao demonstrar o app para outra pessoa.
3. Para registrar uma sequência, use **Salvar e adicionar outro**: valor e observação são limpos somente após salvar; tipo, âmbito, categoria e data são mantidos e o foco volta ao valor. Use o salvamento normal para voltar ou a seta de retorno para encerrar a sequência. Na edição, apenas o salvamento normal é oferecido.
4. Registre uma despesa do negócio ou um gasto **Pessoal**. No **Início**, alterne Negócio/Pessoal/Todos para filtrar os totais e os recentes; a seleção é mantida durante a navegação nessa sessão, não após reiniciar o app. Registros pessoais não entram nos totais identificados como do negócio nem no acompanhamento anual comercial.
5. Consulte **Histórico** para localizar ou corrigir um lançamento e **Ano** para acompanhar o que foi informado.
6. Em **Ajustes → Exportar CSV** ou **Exportar PDF**, escolha data de referência, período (dia/semana/mês/ano), âmbitos, tipos e se inclui observações; confira a prévia e use **Salvar** (seletor de arquivos local) ou **Compartilhar** (Share Sheet nativo), no formato escolhido. Nenhum formato é backup restaurável nem documento fiscal. O PDF é paginado e inclui os mesmos totais e critérios de retirada do CSV; veja [limites e validação do PDF](docs/hermes/EXPORTACAO-PDF.md).
7. Se desejar, abra **Ajustes → Configurar lembrete**, escolha dia e horário e ative o aviso. Confira sempre a situação do DAS nos canais oficiais.

## Retirada do titular (FB08)

No **Início → Pagar-me**, informe valor positivo em pt-BR, data e observação opcional. O app registra as duas pontas da movimentação **Negócio → Pessoal** em uma transação. Toque numa ponta no Histórico ou nos recentes para editar/excluir o par; a confirmação explica que ambas são afetadas. Não use um lançamento comum para registrar novamente a outra ponta.

Entradas/Saídas mostram apenas movimentos comuns. **Retiradas para você** e **Recebido do negócio** explicam o efeito por âmbito; em **Todos**, internas não afetam entradas, saídas nem balanço, inclusive em CSV/PDF com filtro de tipo. O anual continua somando apenas entradas comerciais externas. O app permite registrar retirada com balanço negativo: histórico parcial não informa capacidade de pagamento. Não calcula encargos, folha, lucro distribuível ou classificação automática de pró-labore/lucros.

O SQLite passa de esquema 1 para **2** por migração aditiva, sem inferir vínculos de registros antigos. Preferências não são alteradas. Voltar o código para `rollback/pre-retiradas-9619b3a` **não** restaura dados e não autoriza instalar um APK de esquema 1 sobre a base migrada. Não existe downgrade de dados implementado. Consulte [modelagem, cálculos, testes e reversibilidade](docs/hermes/RETIRADA-TITULAR.md).

## Uso no celular, sem cabo e sem internet

Depois que o APK é instalado, **o cabo USB pode ser desconectado**: ele foi necessário para instalação e depuração, não para abrir ou usar o aplicativo. Os lançamentos e configurações ficam no próprio aparelho; as funções centrais de registro e consulta não exigem conexão com a internet nem conta no NotaMei. Encerrar e reabrir o app normalmente não apaga os lançamentos.

**Cuide dos dados:** limpar os dados do aplicativo ou desinstalá-lo pode apagar os registros locais. O NotaMei oferece **relatórios CSV e PDF** em Ajustes para salvar ou compartilhar os dados fora do app; **não há backup/restauração próprios, conta ou sincronização**. Nenhum relatório é restaurável. Eventuais cópias feitas pelo sistema Android dependem das configurações do aparelho e **não devem ser presumidas como backup garantido**.

Os lembretes dependem de permissão de notificações e das políticas de agendamento e economia de bateria do Android. O app solicita a permissão ao ativar o lembrete; não há garantia de entrega pontual. Para dias 29, 30 ou 31 em meses mais curtos, o aviso é ajustado para o último dia do mês. Há uma janela de agendamentos futuros renovada ao abrir o app.

## Limites importantes

- **Não é um sistema bancário:** não acessa contas, extratos ou Pix; nenhum valor é importado automaticamente.
- **Não apura obrigações fiscais:** o resumo anual considera apenas entradas do negócio que você registrou. Não certifica faturamento fiscal, lucro, limite legal, regularidade ou meses sem movimento.
- **Exportação CSV/PDF não é backup nem documento fiscal:** os relatórios servem para levar os dados para fora do app; não podem restaurar o banco e não comprovam faturamento, regularidade ou quitação. Consulte [CSV](docs/hermes/EXPORTACAO-CSV.md) e [PDF](docs/hermes/EXPORTACAO-PDF.md).
- **Não consulta nem paga o DAS:** o dia do lembrete é escolhido por você, **não** é um vencimento legal calculado pelo app. O aviso não confirma emissão, pagamento ou quitação. Consulte os canais oficiais e, quando necessário, orientação contábil.
- **Não é uma versão de distribuição:** o APK de depuração serve para testes e apresentação. Uma distribuição pública requer preparação e assinatura próprias, além de validações adicionais.

## Colaboração da equipe e uso de IA

Pedro Isaque é o proprietário do repositório e, no momento, o único integrante que usa Hermes. As orientações dos colaboradores são independentes de IA/assinatura; não presumem que todos tenham Hermes ou acesso ao mesmo ambiente.

- [Checklist de Matheus Rocha, Raphael Max e Luchie Bonates](docs/colaboracao/CHECKLIST-EQUIPE.md), com papéis propostos, prioridades e critérios de aceite.
- [Diagnóstico do repositório e limites da inspeção](docs/colaboracao/DIAGNOSTICO-REPOSITORIO.md).
- [Benchmark de funcionalidades e esforço relativo](docs/colaboracao/BENCHMARK-FUNCIONALIDADES.md).
- [Guia para trabalhar com IA](docs/colaboracao/GUIA-IA-EQUIPE.md) e [contrato de tarefa pequena](docs/colaboracao/TAREFA-PARA-IA.md).
- [AGENTS.md](AGENTS.md) e skills compartilháveis em `.agents/skills/` — carregar/fornecer manualmente quando a ferramenta não as reconhecer. Orientações não garantem ausência de alucinações nem dispensam revisão/testes.

São documentos versionáveis, sem dados privados. Novas funcionalidades do benchmark são propostas, não autorização automática para implementar.

## Tecnologia e desenvolvimento

O aplicativo é desenvolvido em **Flutter/Dart** para Android. Lançamentos são persistidos em SQLite (`sqflite`); preferências de primeiro uso e lembrete usam `shared_preferences`; o agendamento local usa `flutter_local_notifications`; a saída CSV/PDF usa `flutter_file_dialog` e `share_plus`, e a renderização PDF usa o pacote `pdf` com assets locais. Não há backend ou sincronização implementados nesta versão.

Estrutura principal:

```text
lib/app/         Inicialização visual e navegação
lib/onboarding/  Primeiro uso e tour
lib/finance/     Início, formulário e histórico
lib/annual/      Acompanhamento anual descritivo
lib/das/         Configuração e agendamento de lembretes
lib/data/        Modelo e persistência dos lançamentos
lib/export/      Seleção/prévia comum, geradores CSV/PDF e gateway nativo
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

## Visual V5 Editorial B

O novo visual está implementado em Flutter no Início, Histórico, formulário/edição, Ano, tour e Ajustes/DAS. Preserva a marca N, usa fontes locais Inter e Playfair Display e destaca **entradas em verde** e **saídas em vermelho**. No Início, a ação de novo lançamento fica no fluxo, sem botão flutuante sobre os registros. V5 é o nome da família visual; não altera a versão do produto para 5.0.

Consulte o [recorte implementado, validações e limites do V5](docs/hermes/V5-IMPLEMENTACAO.md). A interface foi exercitada no emulador. Após alinhar também o ícone Android à paleta V5, a suíte integrada teve 95 testes aprovados, análise estática limpa e novo APK debug com assets conferidos. O novo visual ainda precisa de avaliação no aparelho físico.

## Estado do projeto

Esta versão cobre o fluxo local de apresentação, uso manual e **relatórios CSV/PDF**, acessíveis em Ajustes. **Backup/restauração próprios, sincronização, integrações externas e regras fiscais automáticas não estão implementados**. Relatórios não são restauráveis nem documentos fiscais. Documentos de pesquisa individual e referências visuais de terceiros são materiais locais ignorados pelo Git e não fazem parte da distribuição do aplicativo.

Para continuar o desenvolvimento com o Hermes Agent em outro computador, consulte [as instruções de migração para Windows](docs/hermes/IMPORTAR-WINDOWS.md) e a [síntese compartilhável de requisitos e arquitetura](docs/hermes/REQUISITOS-ARQUITETURA.md). Elas transferem apenas conhecimento revisado e não incluem respostas individuais da pesquisa, conversas ou credenciais.

A [documentação de arquitetura C4](docs/arquitetura/C4-NOTAMEI.md) relaciona a implementação atual aos direcionadores acadêmicos, explicita as lacunas de IA/API e separa propostas futuras. Os [diagramas em HTML](docs/arquitetura/c4-notamei.html) podem ser abertos sem internet. Os PDFs e as respostas brutas permanecem locais em uma pasta ignorada pelo Git.

### Requisitos, decisões e verificação

- [Catálogo de RF, classificação das regras e RNF mensuráveis](docs/hermes/REQUISITOS-ARQUITETURA.md): IDs preservados, prioridades propostas e distinção entre código existente, metas e validação pendente.
- [ADRs de decisões observadas](docs/arquitetura/decisoes/README.md): núcleo local, SQLite/transações e centavos exatos; registros retrospectivos com ratificação pendente, não atas históricas.
- [Matriz de rastreabilidade](docs/arquitetura/RASTREABILIDADE.md): requisitos/feedbacks → decisões/componentes → cobertura e planos de verificação. Metas propostas e testes citados não significam aprovação ou nova execução.

A organização aproveita boas práticas de requisitos e C4 de um enunciado acadêmico, sem executar seu cenário fictício nem impor backend, endpoints HTTP, visibilidade pública ou arquivo único ao NotaMei. Novas funcionalidades, incluindo despesas anuais de T10, mantêm seu estado de planejamento até implementação e testes próprios.
