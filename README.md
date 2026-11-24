# NotaMei

**Organização financeira simples para o microempreendedor individual (MEI).**

O NotaMei é um aplicativo Android desenvolvido em Flutter para ajudar a registrar, consultar e acompanhar movimentações financeiras informadas pela própria pessoa. É um projeto acadêmico extensionista em estágio de **MVP** (primeira versão funcional): prioriza lançamentos manuais, separação entre negócio e vida pessoal e uma leitura clara do histórico, sem substituir controles contábeis ou canais oficiais.

> **Em uma frase:** anote entradas e saídas, veja o balanço mensal do negócio e configure um lembrete pessoal para conferir o DAS.

## Disponibilidade e primeira beta

A [pré-release **v1.0.0-beta.1**](https://github.com/Isaqueodev/NotaMei/releases/tag/v1.0.0-beta.1) foi publicada no GitHub em **23/11/2026**, com APK Android **1.0.0-beta.1, build 7**, assinado com a identidade definitiva do projeto, e arquivo `SHA256SUMS.txt`.

**Código e beta públicos:** o repositório está aberto sob [licença MIT](LICENSE), e a pré-release pode ser consultada e baixada sem acesso de colaborador. A disponibilidade pública não transforma o MVP em versão estável nem comprova validação ampla com usuários.

- Baixe `notamei-1.0.0-beta.1-build7-android.apk` e confira seu SHA-256 com `SHA256SUMS.txt` na mesma release.
- Esta é uma **beta de avaliação**, não uma versão estável nem uma publicação na Play Store. Não há binário iOS nesta entrega.
- O APK foi conferido quanto a assinatura, certificado, pacote, versão, arquiteturas e integridade. **O binário desta beta ainda não foi instalado ou exercitado em aparelho.** Ensaios anteriores com APK debug não equivalem ao aceite deste arquivo.
- A identidade de assinatura difere dos APKs debug anteriores. **Não desinstale, não limpe dados nem force downgrade para substituir uma instalação existente.** A migração precisa preservar o histórico e ser validada separadamente.

## Pesquisa e contexto extensionista

O NotaMei não se baseia apenas em uma proposta de software: há um diagnóstico exploratório e uma avaliação posterior do protótipo, com questionário de feedback e entrevista semiestruturada registrados. Essas etapas têm objetivos e limites diferentes:

| Etapa | Evidência registrada | O que permite afirmar |
| --- | --- | --- |
| Diagnóstico inicial | Nove respostas de questionário, conforme o registro acadêmico histórico do projeto. | Subsídio exploratório para compreender o problema e formular requisitos; não representa a população de MEIs e não equivale a nove testes do aplicativo. |
| Avaliação do protótipo | Uma pessoa MEI respondeu a um questionário de feedback e a uma entrevista semiestruturada: dois instrumentos complementares da mesma pessoa. | Há entrevista e retorno individual sobre o protótipo; não são duas pessoas, uma amostra ampla ou prova de adoção sustentada. |
| Verificação técnica | Testes automatizados e ensaios Android identificados na documentação. | Evidências de funcionamento nos cenários exercitados; não substituem avaliação pela comunidade nem medem impacto financeiro. |

As contagens de diagnóstico e avaliação não são somadas como pessoas distintas: a possível sobreposição não foi verificada. O número do diagnóstico é um registro histórico, não uma nova coleta ou recontagem dos instrumentos nesta revisão.

A avaliação apontou necessidades de continuidade entre meses, consulta de despesas anuais e clareza na separação Negócio/Pessoal. Continuidade histórica e despesas anuais foram incorporadas ao código; isso não significa que a versão resultante tenha sido novamente aprovada pelo participante. Outras sugestões permanecem propostas, não funcionalidades prometidas.

- [Síntese da avaliação, origem dos instrumentos e limites metodológicos](docs/avaliacao/FEEDBACK-MEI-2026-11-04.md).
- [Melhorias rastreadas aos feedbacks e situação de implementação](docs/avaliacao/BACKLOG-MELHORIAS.md).
- [Requisitos e decisões de arquitetura](docs/arquitetura/C4-NOTAMEI.md).

Os instrumentos preenchidos, contatos, assinaturas, imagens e dados identificáveis permanecem fora do GitHub. Publicar o código não autoriza publicar esses materiais. As evidências públicas são sínteses; eventual apresentação dos originais à banca deve ocorrer por meio reservado e com autorização adequada. Não se declara representatividade, parceria formal, impacto comunitário medido ou devolutiva concluída sem evidência própria.

## O que é possível fazer

| Área | Funcionalidade |
| --- | --- |
| Primeiro uso | Escolher entre um tour opcional e começar direto; rever o tour em **Ajustes**. |
| Lançamentos | Registrar **entrada** ou **saída**, valor em reais, data, categoria e observação opcional; classificar manualmente como **Negócio** ou **Pessoal**. Usar **Salvar e adicionar outro** para continuar no formulário, ou o salvamento normal para voltar. Editar e excluir registros. |
| Início | Consultar entradas, saídas, balanço e lançamentos recentes no mês selecionado, filtrando **Negócio**, **Pessoal** ou **Todos**. O padrão é Negócio; Todos identifica explicitamente a soma geral dos dois âmbitos. O balanço considera também retiradas enviadas/recebidas por âmbito, sem duplicar internas em Todos; não é saldo bancário. |
| Pagar-me | Registrar uma **Retirada do titular**: saída do Negócio e entrada no Pessoal vinculadas, com edição/exclusão conjunta. Não duplica entradas/saídas gerais nem receita anual. É registro manual, sem transferência real ou classificação fiscal automática. |
| Histórico | Navegar por mês e filtrar os registros por Negócio/Pessoal e Entrada/Saída. |
| Continuidade | Acompanhar o acumulado dos registros informados desde o primeiro lançamento, separado do balanço mensal e sem saldo inicial manual. Histórico parcial não equivale a saldo bancário. |
| Ano | Consultar entradas e despesas externas do **Negócio**, por mês e no total do ano, excluindo Pessoal e retiradas. Meses sem registro não são tratados como meses sem movimento. |
| Ajustes | Configurar lembrete local do DAS, rever o tour e exportar CSV/PDF. Criar backup financeiro JSON e importar com prévia/confirmação: adicionar sem apagar, ignorar IDs idênticos e bloquear conflitos. Configurações não são restauradas. |

### Exemplo de uso

1. Ao abrir o aplicativo pela primeira vez, escolha **Ver como funciona** ou **Começar sem tour**.
2. Em **Início**, toque em **Novo Lançamento** e registre, por exemplo, uma venda como entrada do **Negócio**. Use exemplos fictícios ao demonstrar o app para outra pessoa.
3. Para registrar uma sequência, use **Salvar e adicionar outro**: valor e observação são limpos somente após salvar; tipo, âmbito, categoria e data são mantidos e o foco volta ao valor. Use o salvamento normal para voltar ou a seta de retorno para encerrar a sequência. Na edição, apenas o salvamento normal é oferecido.
4. Registre uma despesa do negócio ou um gasto **Pessoal**. No **Início**, alterne Negócio/Pessoal/Todos para filtrar os totais e os recentes; a seleção é mantida durante a navegação nessa sessão, não após reiniciar o app. Registros pessoais não entram nos totais identificados como do negócio nem no acompanhamento anual comercial.
5. Consulte **Histórico** para localizar ou corrigir um lançamento e **Ano** para acompanhar o que foi informado.
6. Em **Ajustes → Exportar CSV** ou **Exportar PDF**, escolha data de referência, período (dia/semana/mês/ano), âmbitos, tipos e se inclui observações; confira a prévia e use **Salvar** (seletor de arquivos local) ou **Compartilhar** (Share Sheet nativo), no formato escolhido. Nenhum formato é backup restaurável nem documento fiscal. O PDF é paginado e inclui os mesmos totais e critérios de retirada do CSV; veja [limites e validação do PDF](docs/hermes/EXPORTACAO-PDF.md).
7. Se desejar, abra **Ajustes → Configurar lembrete**, escolha dia e horário e ative o aviso. Confira sempre a situação do DAS nos canais oficiais.
8. Em **Ajustes → Criar backup**, leia os avisos, confirme ciência dos dados legíveis e use **Escolher local e salvar**. A cópia inclui todo o histórico e as observações. Confira o arquivo no destino. Veja [criação e limites](docs/backup/INTERFACE-CRIACAO.md).
9. Em **Ajustes → Importar backup**, escolha um JSON do NotaMei e confira novos registros, idênticos e conflitos. Confirme ciência e toque em **Confirmar e importar**. A importação **não apaga nem substitui registros**; IDs idênticos são ignorados e qualquer conflito bloqueia o arquivo inteiro. Se o histórico mudar após a prévia, selecione novamente. Veja [regras e validação da importação](docs/backup/IMPORTACAO.md).

## Retirada do titular (FB08)

No **Início → Pagar-me**, informe valor positivo em pt-BR, data e observação opcional. O app registra as duas pontas da movimentação **Negócio → Pessoal** em uma transação. Toque numa ponta no Histórico ou nos recentes para editar/excluir o par; a confirmação explica que ambas são afetadas. Não use um lançamento comum para registrar novamente a outra ponta.

Entradas/Saídas mostram apenas movimentos comuns. **Retiradas para você** e **Recebido do negócio** explicam o efeito por âmbito; em **Todos**, internas não afetam entradas, saídas nem balanço, inclusive em CSV/PDF com filtro de tipo. O anual continua somando apenas entradas comerciais externas. O app permite registrar retirada com balanço negativo: histórico parcial não informa capacidade de pagamento. Não calcula encargos, folha, lucro distribuível ou classificação automática de pró-labore/lucros.

O SQLite passa de esquema 1 para **2** por migração aditiva, sem inferir vínculos de registros antigos. Preferências não são alteradas. Voltar o código para `rollback/pre-retiradas-9619b3a` **não** restaura dados e não autoriza instalar um APK de esquema 1 sobre a base migrada. Não existe downgrade de dados implementado. Consulte [modelagem, cálculos, testes e reversibilidade](docs/hermes/RETIRADA-TITULAR.md).

## Uso no celular, sem cabo e sem internet

Depois que o APK é instalado, **o cabo USB pode ser desconectado**: ele foi necessário para instalação e depuração, não para abrir ou usar o aplicativo. Os lançamentos e configurações ficam no próprio aparelho; as funções centrais de registro e consulta não exigem conexão com a internet nem conta no NotaMei. Encerrar e reabrir o app normalmente não apaga os lançamentos.

**Cuide dos dados:** limpar os dados ou desinstalar pode apagar os registros locais. Ajustes oferece **relatórios CSV/PDF, criação de backup JSON e importação aditiva do JSON**. Não há conta ou sincronização. CSV/PDF não podem ser importados; configurações não são restauradas. O JSON inclui observações e é legível, sem senha: guarde e confira sua cópia antes de depender dela. Cópias do sistema Android dependem das configurações do aparelho e não são backup garantido. A importação não substitui o histórico e recusa conflitos; não recomenda limpeza de dados para contorná-los.

Os lembretes dependem de permissão de notificações e das políticas de agendamento e economia de bateria do Android. O app solicita a permissão ao ativar o lembrete; não há garantia de entrega pontual. Para dias 29, 30 ou 31 em meses mais curtos, o aviso é ajustado para o último dia do mês. Há uma janela de agendamentos futuros renovada ao abrir o app.

## Limites importantes

- **Não é um sistema bancário:** não acessa contas, extratos ou Pix; nenhum valor é importado automaticamente.
- **Não apura obrigações fiscais:** o resumo anual usa registros manuais do negócio. Não certifica faturamento fiscal, lucro, limite legal, regularidade ou meses sem movimento.
- **Exportação CSV/PDF não é backup nem documento fiscal:** os relatórios servem para levar os dados para fora do app; não podem restaurar o banco e não comprovam faturamento, regularidade ou quitação. Consulte [CSV](docs/hermes/EXPORTACAO-CSV.md) e [PDF](docs/hermes/EXPORTACAO-PDF.md).
- **Não consulta nem paga o DAS:** o dia do lembrete é escolhido por você, **não** é um vencimento legal calculado pelo app. O aviso não confirma emissão, pagamento ou quitação. Consulte os canais oficiais e, quando necessário, orientação contábil.
- **Beta não é versão estável:** há uma pré-release assinada disponível publicamente no GitHub. Ela ainda requer validação do binário exato em ambiente Android seguro e não garante compatibilidade ou ausência de defeitos em todos os aparelhos.

## Colaboração da equipe e uso de IA

As orientações de contribuição são independentes de ferramenta de IA ou assinatura paga. Não é necessário usar Hermes para desenvolver o projeto; cada colaborador deve conferir seu ambiente, trabalhar em um escopo pequeno e submeter as alterações à revisão.

- [Checklist de Matheus Rocha, Raphael Max e Luchie Bonates](docs/colaboracao/CHECKLIST-EQUIPE.md), com papéis propostos, prioridades e critérios de aceite.
- [Diagnóstico do repositório e limites da inspeção](docs/colaboracao/DIAGNOSTICO-REPOSITORIO.md).
- [Benchmark de funcionalidades e esforço relativo](docs/colaboracao/BENCHMARK-FUNCIONALIDADES.md).
- [Guia para trabalhar com IA](docs/colaboracao/GUIA-IA-EQUIPE.md) e [contrato de tarefa pequena](docs/colaboracao/TAREFA-PARA-IA.md).
- [AGENTS.md](AGENTS.md) e skills compartilháveis em `.agents/skills/` — carregar/fornecer manualmente quando a ferramenta não as reconhecer. Orientações não garantem ausência de alucinações nem dispensam revisão/testes.

Os documentos compartilháveis devem ser revisados antes da publicação. Novas funcionalidades do benchmark são propostas, não autorização automática para implementar.

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
lib/backup/      Criação, leitura limitada, prévia e importação aditiva em Ajustes
test/            Testes automatizados por área
```

Para desenvolver localmente, prepare um Flutter SDK compatível com `pubspec.yaml`, Android SDK e JDK compatível com a configuração Gradle. Use um emulador ou aparelho dedicado com dados fictícios; um iPhone não executa o APK Android. Na raiz do projeto:

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

O arquivo gerado fica em `build/app/outputs/flutter-apk/app-debug.apk`. Ele usa a identidade de desenvolvimento, não a identidade da beta distribuída. Antes de instalar qualquer APK sobre outro, confira pacote, certificado, versão e preservação dos dados; não contorne incompatibilidades com desinstalação ou limpeza. Depois de uma instalação validada, a execução normal não depende de ADB.

## Assinatura para distribuição Android

O build `release` exige uma chave própria fora do repositório e credenciais efêmeras no ambiente do processo. **Não há fallback para a assinatura debug.** O build de depuração acima continua disponível sem essas credenciais.

Consulte [configuração, bloqueios e validação da assinatura](docs/entrega/ASSINATURA-ANDROID.md). A configuração não publica uma release nem autoriza substituir o aplicativo já instalado no celular.

Para reproduzir os parâmetros da beta, **somente após fornecer as credenciais ao processo por meio seguro**:

```sh
flutter build apk --release --no-pub --no-android-gradle-daemon --build-name 1.0.0-beta.1 --build-number 7 --android-project-arg kotlin.compiler.execution.strategy=in-process
```

O `pubspec.yaml` do commit da beta continua com `1.0.0+1`: nome e build da entrega foram definidos pelos parâmetros acima, não por uma alteração versionada desse arquivo. Uma compilação própria pode usar outra chave e não se torna uma atualização oficial apenas por repetir esses parâmetros. Nunca coloque senhas em comandos, arquivos versionados, `--dart-define`, issues ou PRs.

### Verificações registradas

Na base da beta, commit `e47d637`, foram registrados em **23/11/2026**:

| Verificação local | Resultado |
| --- | --- |
| Suíte Flutter | 228 testes aprovados, sem pulos |
| `flutter analyze` | Sem problemas encontrados |
| Política de assinatura e recuperação de artefatos | 33 testes aprovados |
| APK da beta | Assinatura definitiva, fingerprint, manifesto e SHA-256 conferidos; download do asset remoto comparado à origem |

Esses resultados não equivalem a CI configurada, teste físico deste APK ou validação completa de TalkBack, provedores de arquivos e versões Android. Para repetir as verificações de assinatura, veja os pré-requisitos e o comando `python tool/test_release_signing.py` na [documentação de assinatura](docs/entrega/ASSINATURA-ANDROID.md); a suíte usa chaves descartáveis, não a chave oficial.

## Identidade visual

A interface preserva a marca N, usa **Roboto local** nos temas claro/escuro e distingue entradas em verde e saídas em vermelho. A fonte **Inter** é um recurso local do gerador de PDF; não é a família atual da interface.

O [documento de implementação V5](docs/hermes/V5-IMPLEMENTACAO.md) registra uma etapa histórica da evolução visual. Seus números de testes e fontes daquela etapa não substituem o estado atual do código e dos assets. V5 não é a versão comercial 5.0 do aplicativo.

## Estado do projeto

Esta versão cobre uso manual, **relatórios CSV/PDF** e **criação/importação aditiva de backup JSON**, acessíveis em Ajustes. **Substituição integral do histórico, restauração de preferências, sincronização, integrações externas e regras fiscais automáticas não estão implementadas**. Relatórios não são restauráveis nem documentos fiscais. Instrumentos preenchidos de pesquisa e referências privadas de terceiros não fazem parte da distribuição.

**Backup financeiro:** a [criação](docs/backup/INTERFACE-CRIACAO.md) usa o [serviço de saída](docs/backup/CRIACAO.md) e o [formato v1](docs/backup/FORMATO-V1.md). A [importação](docs/backup/IMPORTACAO.md) integra seletor Android com leitura limitada, prévia congelada e gravação transacional aditiva. JSON continua legível, sem senha/criptografia; não inclui preferências. Há testes com canais simulados/SQLite temporário e ensaios Android anteriores em build debug. Isso não valida automaticamente o APK desta beta, todos os provedores de arquivos ou os recursos assistivos.

Para continuar o desenvolvimento com o Hermes Agent em outro computador, consulte [as instruções de migração para Windows](docs/hermes/IMPORTAR-WINDOWS.md) e a [síntese compartilhável de requisitos e arquitetura](docs/hermes/REQUISITOS-ARQUITETURA.md). Elas transferem apenas conhecimento revisado e não incluem respostas individuais da pesquisa, conversas ou credenciais.

A [documentação de arquitetura C4](docs/arquitetura/C4-NOTAMEI.md) relaciona a implementação atual aos direcionadores acadêmicos, explicita as lacunas de IA/API e separa propostas futuras. Os [diagramas em HTML](docs/arquitetura/c4-notamei.html) podem ser abertos sem internet. Os PDFs e as respostas brutas permanecem locais em uma pasta ignorada pelo Git.

### Requisitos, decisões e verificação

- [Catálogo de RF, classificação das regras e RNF mensuráveis](docs/hermes/REQUISITOS-ARQUITETURA.md): IDs preservados, prioridades propostas e distinção entre código existente, metas e validação pendente.
- [ADRs de decisões observadas](docs/arquitetura/decisoes/README.md): núcleo local, SQLite/transações e centavos exatos; registros retrospectivos com ratificação pendente, não atas históricas.
- [Matriz de rastreabilidade](docs/arquitetura/RASTREABILIDADE.md): requisitos/feedbacks → decisões/componentes → cobertura e planos de verificação. Metas propostas e testes citados não significam aprovação ou nova execução.

A organização aproveita boas práticas de requisitos e C4 de um enunciado acadêmico, sem executar seu cenário fictício nem impor backend, endpoints HTTP, visibilidade pública ou arquivo único ao NotaMei. Despesas anuais e continuidade histórica já estão implementadas; outros itens de backlog continuam propostas até implementação e validação próprias.

## Privacidade e licença

- Não envie bancos reais, backups financeiros, respostas individuais de pesquisa, contatos, fotos sem autorização, logs privados, senhas ou keystores ao Git, às issues/PRs ou aos anexos de releases.
- Use dados fictícios em testes e demonstrações. Não presuma anonimização apenas porque observações foram omitidas de um relatório.
- `.gitignore` ajuda a evitar inclusões comuns, mas não remove histórico nem protege arquivos já rastreados ou adicionados com força. A abertura do repositório não elimina cópias antigas ou referências retidas; revise conteúdo, histórico e anexos ao publicar.
- O certificado público de assinatura, seu fingerprint, hashes do APK, nomes de variáveis e identificação do pacote não são a chave privada. A chave e suas senhas permanecem fora da distribuição.
- Código sob [licença MIT](LICENSE). Fontes e demais recursos preservam suas licenças e avisos próprios.
