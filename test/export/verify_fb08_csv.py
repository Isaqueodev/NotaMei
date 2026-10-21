"""Independent parser check for the synthetic FB08 fixture, never user data.
Run after: flutter test test/export/withdrawal_csv_test.dart
"""
import csv
from pathlib import Path


def main():
    raw = Path("build/fb08-synthetic.csv").read_bytes()
    assert raw.startswith(bytes([239, 187, 191])), "UTF-8 BOM missing"
    lines = raw.decode("utf-8-sig").splitlines(keepends=True)
    rows = list(csv.reader(lines, delimiter=";", strict=True))
    assert len(rows) == 10
    assert {len(row) for row in rows} == {15}, "Non-uniform rows"
    data = list(csv.DictReader(lines, delimiter=";", strict=True))
    legs = [row for row in data if row["withdrawal_id"]]
    assert len(legs) == 2
    assert all(row["withdrawal_id"] == "\t=synthetic" for row in legs)
    assert all(row["natureza"] == "Retirada do titular" for row in legs)
    assert all(row["observacao"] == '\t=sintético; "teste"\nlinha' for row in legs)
    assert {row["ambito"] for row in legs} == {"Negócio", "Pessoal"}
    totals = {row["tipo"]: row["valor_brl"] for row in data if row["secao"] == "Resumo"}
    assert totals == {
        "Entradas": "1000,00",
        "Saídas": "200,00",
        "Transferências enviadas": "300,00",
        "Transferências recebidas": "300,00",
        "Balanço dos registros selecionados": "800,00",
    }
    assert all("internas excluídas dos totais consolidados mesmo com filtro de tipo" in row["criterio_resumo"] for row in data)
    print(f"Python csv: {len(rows)} linhas x {len(rows[0])} colunas; BOM, vínculo, TAB, escape, multiline e 5 totais conferidos.")


if __name__ == "__main__":
    main()
