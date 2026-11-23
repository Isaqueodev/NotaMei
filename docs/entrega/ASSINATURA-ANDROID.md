# Assinatura de distribuicao Android

## Contrato deste projeto

`debug` continua usando a assinatura de desenvolvimento do Android. `release` usa exclusivamente a configuracao `release`, sem fallback para debug. Empacotamento/assinatura de release exige chave privada fora do repositorio e credenciais no ambiente do processo; compilacao, lint e testes unitarios de release nao exigem segredos de distribuicao.

Esta configuracao nao publica uma release, nao altera a visibilidade do GitHub e nao instala APK no aparelho. Assinatura de APK e modo de compilacao sao verificacoes distintas.

## Entradas locais ou de CI

| Variavel de ambiente | Obrigatoria | Conteudo |
|---|---|---|
| `NOTAMEI_SIGNING_STORE_FILE` | Sim | Caminho absoluto para keystore fora do repositorio |
| `NOTAMEI_SIGNING_STORE_PASSWORD` | Sim | Senha do keystore |
| `NOTAMEI_SIGNING_KEY_ALIAS` | Sim | Alias da entrada de chave privada |
| `NOTAMEI_SIGNING_KEY_PASSWORD` | Sim | Senha da chave; declarar explicitamente, mesmo se igual a do keystore |
| `NOTAMEI_SIGNING_STORE_TYPE` | Nao | `PKCS12` por padrao; `JKS` tambem aceito pela configuracao |
| `NOTAMEI_SIGNING_CERT_SHA256` | Nao | Fingerprint esperado do certificado: exatamente 64 caracteres hexadecimais, sem separadores |

O pin do certificado e recomendado para o build oficial. O certificado e seu fingerprint sao publicos; a chave privada e as senhas nao sao. Forks devem usar suas proprias identidades e nao devem se apresentar como atualizacoes oficiais.

Nao sao lidos `key.properties`, `.env`, senhas em propriedades `-P` ou senhas escritas no script Gradle. Uma configuracao legada nesses arquivos nao habilita release. Nunca use `--dart-define` para uma senha de assinatura: nao e um canal de segredo de build Android.

### Fornecimento seguro

- Use um gerenciador de senhas para custodia. No build local, injete as senhas em uma sessao/processo efemero por entrada mascarada, sem echo, e encerre essa sessao ao terminar.
- Nao escreva comandos com o valor literal da senha, pois podem ir para historico/logs. Nao grave o valor em perfil de shell, arquivos versionados ou configuracao global.
- Em CI, use o mecanismo de secrets da plataforma e restrinja quem pode executar o build de distribuicao. Nao publique o keystore como artifact. O armazenamento/copia temporaria do keystore exige tratamento privado proprio.
- Nao compartilhe logs de `--debug`, build scans, dumps de memoria ou caches de uma sessao com credenciais. Heap dump automatico e configuration cache ficam desabilitados por padrao. Alem desse padrao, o estado efetivamente ativo do configuration cache e consultado pelo servico publico `BuildFeatures`: quando o cache esta ativo, a presenca de qualquer variavel de senha (mesmo vazia) causa `NOTAMEI_SIGNING_CACHE` durante configuracao, antes de preencher o modelo de assinatura, inclusive em debug/help e com `--configuration-cache-problems=warn`.
- O Gradle e o assinador precisam das credenciais em memoria para trabalhar. Estas medidas nao protegem um computador comprometido nem tornam seguro imprimir o ambiente.
- Limpar arrays temporarios de caracteres nao apaga as strings originais do Gradle/JVM. Os ignores evitam a adicao comum de arquivos nao rastreados; nao protegem chaves ja rastreadas ou adicionadas com force.

Somente depois de as variaveis estarem no ambiente protegido do processo:

```sh
flutter build apk --release --no-pub --no-android-gradle-daemon
```

Para diagnostico sem produzir APK:

```sh
# macOS / Linux, dentro de android/
./gradlew :app:validateReleaseSigning --no-daemon --no-configuration-cache
```

```powershell
# Windows, dentro de android/
.\gradlew.bat :app:validateReleaseSigning --no-daemon --no-configuration-cache
```

Esses comandos nao recebem senha em argumento. Execute-os apenas em um ambiente onde a injecao segura das variaveis ja tenha sido resolvida. Nunca envie senhas pela conversa nem grave os valores em scripts para completar essa etapa.

## Bloqueios

A tarefa `:app:validateReleaseSigning` verifica entradas obrigatorias nao vazias, arquivo absoluto e caminho canonico fora do repositorio, tipo, abertura com as senhas literais fornecidas, entrada de chave privada, validade do certificado e eventual pin. Nao verifica forca, origem ou custodia das senhas. Todos os valores CN em todos os atributos de cada RDN LDAP sao inspecionados; `CN=Android Debug` e rejeitado inclusive em RDN multivalorado ou arquivo renomeado. O tipo padrao e PKCS12, nao uma identidade padrao de release: nao existe chave de distribuicao embutida. A chave de debug e de desenvolvimento; as fixtures descartaveis da suite nao sao identidade oficial. CN nao comprova identidade legal verificada, nem esta verificacao detecta todo certificado de teste possivel.

Os nomes exatos das tarefas de empacotamento, assinatura e ciclo de producao de artefatos sao derivados das variantes release selecionadas pela API publica `androidComponents`, incluindo nomes de flavors. Esses caminhos dependem da tarefa independente, mas tambem revalidam no grafo antes da execucao e em predicado que lanca erro (nunca uma recusa silenciosa). Assim, excluir `validateReleaseSigning` com `-x` nao remove a politica, nem UP-TO-DATE/FROM-CACHE a contorna. O caminho agregado `assemble` continua protegido por suas tarefas de artefato release. Nao se aplica uma busca generica por Release: compilacao, lint e testes unitarios nao recebem esse gate. `assembleDebug` nao exige credenciais de distribuicao; fornecer senhas junto com configuration cache ativo, contudo, sempre e recusado.

As mensagens `NOTAMEI_SIGNING_*` identificam o problema sem mostrar senhas, caminhos/aliases fornecidos ou excecoes nativas. Um build que falhou nao valida um APK antigo que ainda esteja na pasta de saida.

## Testes da politica

Pre-requisitos: Python 3, JDK com `keytool`, Flutter/Android configurados e wrapper Gradle disponivel. Defina `JAVA_HOME` e o SDK conforme seu ambiente. O teste usa apenas a biblioteca padrao do Python e chaves descartaveis criadas em diretorio temporario; nao recebe nem procura sua chave pessoal.

```sh
python tool/test_release_signing.py
```

O teste limpa variaveis de assinatura herdadas e cria fixtures PKCS12 descartaveis no diretorio temporario do processo (respeitando TMPDIR quando definida), com limpeza ao final. Inclui casos de RDN multivalorado, cache ativo em debug/help, exclusao direta/agregada por `-x`, compilacao release sem segredos, build debug real e APK release real com verificacao de certificado por `apksigner` (build-tools 36.0.0), seguido de reuso do artefato e pin incorreto. APKs antigos nos caminhos exatos dos testes sao preservados por quarentena/restauracao; sua presenca nao prova producao por um build que falhou. A captura bruta e verificada para vazamento literal das senhas antes da redacao dos diagnosticos. Os casos de cache usam cache de projeto temporario. A suite completa pode levar muitos minutos; casos adicionados nao devem ser considerados executados sem resultado real. Estas verificacoes nao sao `flutter test`, aceite oficial, validacao em aparelho ou publicacao.

## Conferencia do APK real

Depois de um build bem-sucedido:

1. Usar `apksigner verify --verbose --print-certs` do SDK no arquivo exato.
2. Conferir o SHA-256 do certificado com o fingerprint esperado da chave de distribuicao, nao apenas se existe alguma assinatura.
3. Conferir pacote, versionName, versionCode, ABIs e ausencia de `debuggable` usando as ferramentas do SDK.
4. Calcular o SHA-256 do APK e registrar commit e parametros do build.
5. Conferir que a chave, senhas, configuracoes locais, bancos reais e fixtures privadas nao foram empacotados.
6. Distinguir verificacao estatica do arquivo de instalacao/uso real. Nao afirmar aceite em aparelho sem executa-lo.

O mesmo pacote assinado por outra identidade pode nao atualizar a versao debug ja instalada. Nao desinstale, limpe dados, force downgrade ou tente contornar assinatura para preparar a demonstracao. Planeje backup e migracao; JSON financeiro nao restaura preferencias. A chave e seus backups devem continuar privados e recuperaveis fora deste computador.

## Fontes oficiais

- Android Developers: `https://developer.android.com/studio/publish/app-signing`
- Flutter: `https://docs.flutter.dev/deployment/android`
- Gradle Task API/configuration cache: `https://docs.gradle.org/current/javadoc/org/gradle/api/Task.html`

Consulte as versoes vigentes para canais de loja, sucessao de chaves e mudancas de plugins. A preparacao da assinatura nao comprova publicacao em loja ou disponibilizacao publica do projeto.
