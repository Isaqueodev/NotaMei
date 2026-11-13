# Plano de versão e atualização (T06)

## Objetivo

Descrever, de forma fictícia e apenas para fins acadêmicos/extensão, um plano de versão e atualização do NotaMei. 

Este documento **não** instrui a gerar um APK de release assinado, não configura chaves e **não** prevê publicação em loja ou na Play Store.

## 1) Candidato à versão

| Campo | Valor |
| --- | --- |
| Nome do aplicativo | NotaMei |
| Versão (pubspec.yaml) | `1.0.0` |
| Build number (pubspec.yaml) | `+1` |
| Versão completa | `1.0.0+1` |
| Tipo atual | MVP - APK de depuração (`flutter build apk --debug`) |
| `publish_to` | `none` (pacote privado, não publicado em pub.dev) |

## 2) Identidade do aplicativo

| Campo | Valor |
| --- | --- |
| `applicationId` (Android) | `br.edu.notamei.notamei` |
| `namespace` (Android) | `br.edu.notamei.notamei` |
| Módulo | `android/app` |
| Arquivo de configuração | `android/app/build.gradle.kts` |

## 3) Assinatura atual

| Campo | Situação |
| --- | --- |
| Assinatura utilizada | **Debug** (`signingConfigs.getByName("debug")`) |
| Configuração para release | Presente em `build.gradle.kts`, porém aponta para a configuração `debug`. Não existe uma configuração customizada para release. |
| `key.properties` | **Não encontrado** no repositório. |
| Arquivos `.jks` / `.keystore` | **Não encontrados** no repositório. |
| Observação | A assinatura atual é exclusivamente para testes e depuração. Quaisquer keystores, aliases, senhas ou arquivos de assinatura são locais ao ambiente e **não devem ser versionados**. |

## 4) Atualização com base fictícia

Para fins de ensaio, considera-se o seguinte cenário **puramente hipotético**:

| Item | Descrição (fictícia) |
| --- | --- |
| Versão candidata | `1.0.1+2` (exemplo apenas para fins documentais. **Nenhuma alteração foi feita em `pubspec.yaml`)** |
| Artefato candidato | `app-release-ficticio.apk` (inexistente neste repositório) |
| Forma de instalação no ensaio | `adb install -r` utilizando um artefato fictício, ou reinstalação do APK debug já utilizado para testes |
| Publicação | **Não prevista.** Não há pipeline, Play Console ou qualquer processo de publicação configurado neste projeto |

**Importante:** Caso fosse realmente necessário gerar um APK release assinado, seria imprescindível um keystore próprio, criação/uso de `key.properties` e **autorização explícita do Pedro**.

## 5) Distinção entre teste e produção

| Aspecto | Teste (atual) | Produção (fictício) |
| --- | --- | --- |
| Assinatura | Chave de debug (sem keystore de release versionado) | Keystore de release próprio, fora do repositório e restrito a quem for autorizado |
| Distribuição | Local, via ADB ou instalação manual para apresentação e testes | Apenas com processo formal, revisão e aprovação. Não existe neste projeto |
| Validação | `flutter analyze`, `flutter test` e validação manual | Exigiria validação ampliada, além da correta configuração de assinatura |
| Segurança/controle | Simplificada para facilitar o desenvolvimento e os testes | Maior controle, com chaves separadas e cuidados com vazamento de credenciais |
| Finalidade | Desenvolvimento, depuração e apresentação | Distribuição para usuários finais (não aplicável a este projeto) |

## 6) Preservação de registros e preferências no ensaio

- **Banco SQLite local:** Os lançamentos ficam armazenados no SQLite local do aparelho. Em ensaios com `adb install -r`, geralmente os dados são preservados, mas **não há garantia** de que isso ocorra em todos os cenários.
- **Preferências:** As configurações salvas com `shared_preferences` (primeiro uso, lembrete do DAS, entre outras) tendem a ser preservadas, mas **também não há garantia**.
- **Limpar dados ou desinstalar:** Ao utilizar "Limpar dados" ou ao desinstalar o aplicativo, **todos os registros locais são apagados**.
- **Sem backup/restauração próprio:** O NotaMei não possui funcionalidade de backup ou restauração nativos. Os relatórios CSV/PDF servem apenas para **exportação**, não para restaurar o banco.
- **Migrações:** Já existem migrações no banco (ex.: retirada do titular). **Não existe mecanismo de downgrade** de esquema/dados implementado.

## 7) Limites

- **Sem publicação:** Este documento não autoriza publicação em nenhuma loja. Qualquer distribuição precisa de aprovação explícita.
- **Sem alterações sensíveis:** Qualquer alteração em `android/` (Gradle), `pubspec.yaml`, `key.properties` ou arquivos de chaves **depende de autorização explícita do Pedro**.
- **Sem invenção:** Não são listados caminhos, aliases, senhas ou conteúdos de keystores. Caso não existam no repositório, são explicitamente tratados como "não encontrados".
- **Sem garantia:** A preservação de dados em ensaios não é garantida. É necessário sempre ter cautela ao reinstalar o app.
- **Sem downgrade:** Não há rota implementada para voltar a um esquema anterior do banco.
- **Sem garantia de lembretes:** O agendamento de lembretes depende de permissões de notificação e das políticas de economia de bateria do Android.
- **Apenas documentação:** Esta tarefa se restringe unicamente à criação deste documento. Nenhum código, configuração de build ou arquivo de assinatura foi alterado.

## 8) Checklist de validação (ensaio)

- [x] Candidato à versão identificado (`1.0.0+1`)
- [x] Identidade do aplicativo registrada (`br.edu.notamei.notamei`)
- [x] Assinatura atual documentada (APK debug). Ausência de keystore de release confirmada
- [x] Distinção entre teste e produção registrada
- [x] Preservação de registros e preferências abordada com ressalvas
- [x] Cenário de atualização com base fictícia documentado
- [x] Limites claramente registrados
- [x] Nenhuma alteração em Gradle/pubspec/chaves realizada
- [ ] Revisado por **Pedro** antes de qualquer ação real de release/publicação

## 9) Registro complementar do candidato de teste — 12/11/2026

O plano e o cenário fictício acima são preservados como entrega original de Matheus na PR #14. Este complemento registra o artefato posteriormente gerado com autorização de Pedro; não transforma o cenário hipotético em ensaio executado nem autoriza publicação ou mudança de chaves.

| Campo | Registro verificado |
| --- | --- |
| Código do candidato | `0cacabcfbb3087a7adc23e2ac3f62531319c8940` (`0cacabc`) |
| Versão no APK | `1.0.0`, build `3`, por argumento de compilação; `pubspec.yaml` continua `1.0.0+1` |
| Artefato local, fora do Git | `NotaMei_0cacabc_2026-11-12_teste.apk` |
| Modo de compilação | Release otimizado **de teste**, universal; não confundir modo release com assinatura de produção |
| Assinatura | Certificado Android Debug, verificado e igual ao APK de teste anterior |
| Pacote / APIs | `br.edu.notamei.notamei`; mínimo 24, alvo 36 |
| ABIs | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Tamanho | `63541567` bytes |
| SHA-256 do APK | `35f8b5a4428cb948fa6f61acd38f16fbee7b3a0a0991447f0827971bfaab7212` |
| Conferências executadas | Compilação, manifesto, assinatura, ZIP e hash após cópia; sem banco/fixtures privados nos caminhos pesquisados |
| Instalação/atualização Android desta entrega | **Não executada**; não comprova preservação de registros/preferências |

A validação real de atualização e reabertura fica em T05, no aparelho/ambiente escolhido por Pedro, sem desinstalar ou limpar dados como atalho. Se houver incompatibilidade de assinatura ou downgrade, parar para decisão, não forçar a instalação. Alterações documentais posteriores não recompilam esse APK nem mudam sua identidade. Ver [estado e coordenação](../colaboracao/ESTADO-E-COORDENACAO.md).
