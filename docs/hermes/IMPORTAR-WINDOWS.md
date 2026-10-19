# Continuar o NotaMei no Hermes Agent do Windows

O aprendizado específico do projeto está **no próprio repositório**, sem exportar sessões do Hermes ou copiar credenciais. A branch para desenvolvimento é `feature/notamei-mvp`; **não** use a `main` (ela não recebeu o MVP nesta etapa). O Git transporta o código, [o contexto revisado](CONTEXTO-NOTAMEI.md), [uma sugestão de memória](MEMORIA-SUGERIDA.md) e a habilidade `.agents/skills/notamei-paralelo/SKILL.md`.

## No Windows

1. Autentique-se no GitHub pelos meios normais do seu computador (não envie senha, token ou chave em mensagens). Abra o clone do NotaMei ou clone-o. Dentro dele, execute `git fetch origin`, `git switch feature/notamei-mvp` e `git pull --ff-only origin feature/notamei-mvp`. Se a branch ainda não existir localmente, use `git switch --track origin/feature/notamei-mvp`. Confira `git status --short --branch`.
2. Abra o PowerShell **na raiz do clone**. O bloco abaixo copia somente a habilidade de projeto para o perfil Hermes ativo; se já existir outra versão da habilidade, preserva-a para comparação manual:

```powershell
$repo = (git rev-parse --show-toplevel).Trim()
if (-not $repo) { throw 'Abra o PowerShell dentro do clone NotaMei.' }
$hermesHome = if ($env:HERMES_HOME) { $env:HERMES_HOME } else { Join-Path $HOME '.hermes' }
$origem = Join-Path $repo '.agents\skills\notamei-paralelo\SKILL.md'
$destino = Join-Path $hermesHome 'skills\notamei-paralelo\SKILL.md'
if (-not (Test-Path -LiteralPath $origem)) { throw 'Habilidade não encontrada: confira a branch.' }
if (Test-Path -LiteralPath $destino) {
    Write-Host "Habilidade já existente preservada: $destino. Compare com $origem antes de atualizar."
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destino) | Out-Null
    Copy-Item -LiteralPath $origem -Destination $destino
    Write-Host "Habilidade copiada para: $destino"
}
```

3. Leia `docs/hermes/MEMORIA-SUGERIDA.md`. Se já existir `$hermesHome\memories\USER.md`, **não sobrescreva** a memória do Windows; acrescente apenas as informações ainda úteis, removendo duplicatas. É uma sugestão, não requisito para executar o app.
4. Inicie uma nova conversa no Hermes do Windows com o clone aberto e peça: “Leia `docs/hermes/CONTEXTO-NOTAMEI.md` e `README.md`, confira `git status`, e só então continue o NotaMei.” Instale Flutter/Android SDK no Windows separadamente; os executáveis e caminhos do Linux não foram exportados.

`hermes import` é para restaurar um backup **completo** do ambiente, não para esta migração seletiva. Não o execute com o ZIP local anteriormente gerado. Aqui a fonte de verdade é o repositório; `git pull` atualiza o conhecimento versionado, mas **não sobrescreve automaticamente** a cópia da habilidade no perfil Hermes — compare versões quando ela mudar.

## Privacidade

O `.gitignore` exclui pesquisa individual, referências de design, artefatos compilados, estado local do Hermes, chaves e arquivos locais Android. Mesmo assim, antes de comitar ou enviar, revise `git status` e o diff staged: regras de ignore não protegem arquivos que já tenham sido rastreados. Não publique respostas individuais, imagens de terceiros ou segredos.
