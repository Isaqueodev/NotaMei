# Backup financeiro — núcleo e contrato v1

## Estado deste incremento

Implementado em `lib/backup/financial_backup.dart`: serialização e validação puras,
sem I/O, acesso ao SQLite ou dependências novas. `encode` produz bytes; `decode`
produz um `FinancialBackup` com lista imutável. **Ainda não existe uma ação de
criar/restaurar backup nos Ajustes.** Este contrato não torna CSV/PDF restauráveis.

O núcleo trabalha apenas com lançamentos financeiros. Preferências, notificações,
senha, criptografia, substituição/mesclagem e localização do arquivo continuam fora
deste incremento. JSON é texto legível: não há confidencialidade, assinatura,
autenticação ou garantia de detecção de adulteração.

## Envelope

UTF-8 válido e JSON com exatamente estas chaves:

```json
{
  "format": "notamei-financial-backup",
  "version": 1,
  "createdAt": "2026-11-18T12:00:00.000Z",
  "entries": [
    {
      "id": "exemplo-ficticio",
      "type": "income",
      "scope": "business",
      "amountCents": "12345",
      "category": "Serviços",
      "date": "2026-11-18T00:00:00.000",
      "note": null,
      "withdrawalId": null
    }
  ]
}
```

- `version` é o número inteiro 1, não texto nem número fracionário. Formatos e
  versões desconhecidos são recusados; não existe migração implícita.
- `createdAt` é ISO canônico de `DateTime.toIso8601String()` em UTC. Na criação,
  somente esse metadado é convertido para UTC.
- `entries` é uma lista, inclusive vazia. A ordem recebida é preservada. Cada
  registro contém exatamente as oito chaves do exemplo; campos anuláveis também
  precisam estar presentes. Chaves ausentes/extras e tipos incorretos são recusados.
- `id` e `category` são textos não vazios após verificação de espaços, mas o valor
  original é preservado: o codec não limpa, renomeia nem normaliza conteúdo.
- `type`: `income` ou `expense`; `scope`: `business` ou `personal`.
- `amountCents` é **texto decimal canônico positivo**, de `1` até
  `9223372036854775807`, conforme `maxMoneyCents`. Isso evita depender da precisão
  de números JSON de outros consumidores. Não aceita ponto decimal, sinal,
  expoente ou zeros à esquerda. Não utiliza `double` para converter dinheiro.
- `date` usa a representação canônica original de `DateTime`: local sem sufixo ou
  UTC com `Z`, incluindo frações de segundo quando existentes. Não converte datas
  de lançamentos entre fusos nem desloca mês/ano civil. Datas impossíveis que o
  parser normalizaria, representações não canônicas e tipos incorretos são recusados.
- `note` é texto ou `null`; vazio, espaços, quebras de linha, acentos e símbolos
  são preservados, sem escape de fórmulas de planilha ou alteração do conteúdo.
- `withdrawalId` é texto não vazio após verificação de espaços, ou `null`. IDs de
  registros precisam ser únicos em todo o arquivo.

## Retirada vinculada

Para cada `withdrawalId`, devem existir exatamente duas pontas:

1. `business` / `expense`, ID `withdrawal:<withdrawalId>:business`;
2. `personal` / `income`, ID `withdrawal:<withdrawalId>:personal`.

Ambas usam `Retirada do titular`, mesmo valor, representação de data e observação.
Essas regras refletem `EntryRepository.saveWithdrawal`. Pares incompletos ou
inconsistentes são recusados; o codec não recria IDs, completa pontas, deduplica,
mescla ou corrige dados automaticamente.

## Limites e falhas

- Máximo de **10 MiB de UTF-8** e **10.000 registros**, sem truncamento. O limite
  de registros conta cada ponta da retirada individualmente. O teste inclui o
  limite exato de bytes e de quantidade, além dos excessos.
- Na leitura, o tamanho é conferido antes de interpretar o JSON. Na criação,
  quantidade e orçamento acumulado de texto são conferidos antes da serialização,
  e o tamanho final inclui escapes JSON e UTF-8. Esses limites não equivalem a
  medição de desempenho ou garantia de resistência a toda entrada hostil.
- Falhas de validação geram `FormatException` sem incluir o conteúdo financeiro
  em `source` ou na mensagem. O parser não escreve arquivos nem altera a base.
- Um arquivo estruturalmente válido pode ter conteúdo alterado e continuar válido:
  não há checksum autenticado ou proteção criptográfica neste incremento.
- A validação cobre formato, registros e vínculos, **não** autorização de restaurar,
  conflito com registros existentes ou todos os limites de totais por mês/ano.
  Essas verificações precisam integrar a futura restauração antes de qualquer escrita.

## Integração futura, ainda pendente

1. Capturar o histórico completo e consistente do repositório, sem filtros de
   mês/ano, âmbito ou tipo da tela. O codec não sabe se o chamador omitiu registros.
2. Escolher destino e salvar os bytes com cancelamento/erros e aviso de dados
   legíveis; não anunciar criação sem verificar a saída. Não sobrescrever arquivos
   existentes por inferência.
3. Ler com limites antes de alocar todo arquivo, validar, apresentar prévia e
   obter confirmação. Definir explicitamente substituir versus mesclar e eventual
   proteção por senha; este contrato não decide essas políticas.
4. Implementar restauração transacional com validação de domínio, tratamento de
   falhas e proteção dos dados anteriores; depois integrar Ajustes e validar no Android.

## Verificação automatizada

```sh
flutter test --no-pub test/backup
flutter analyze --no-pub
```

Os testes cobrem ida/volta de todos os campos, centavos no limite, datas civis,
vazio, observações nulas/vazias, UTF-8/JSON inválidos, formato/versão/tipos, campos,
IDs duplicados, retiradas, limites e ausência de mutação do snapshot original.
Um teste usa SQLite FFI **somente em memória**, inclui meses/anos e âmbitos
diferentes e compara campos e totais antes/depois do codec, sem restauração ou
escrita do codec. Isso não substitui aceite de salvar/restaurar no aparelho.
