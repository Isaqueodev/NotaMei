"""Independent validation of actual synthetic PDFs produced by Flutter tests.
Run: flutter test test/export/pdf_export_test.dart && python test/export/verify_pdf_export.py
Requires pypdf in the Python environment; no user data is read.
"""
from pathlib import Path
import re
from pypdf import PdfReader


def read(name):
    reader = PdfReader(Path('build') / name)
    assert not reader.is_encrypted
    assert reader.metadata.author == 'NotaMei'
    assert not reader.trailer['/Root'].get('/OpenAction')
    text = '\n'.join(page.extract_text() or '' for page in reader.pages)
    assert 'NotaMei' in text and 'Não é documento fiscal nem backup.' in text
    for index, page in enumerate(reader.pages, 1):
        assert f'Página {index} de {len(reader.pages)}' in page.extract_text()
    return reader, re.sub(r'\s+', ' ', text)


def main():
    _, basic = read('pdf-basic-synthetic.pdf')
    for value in ['Entradas: R$ 1000,00', 'Saídas: R$ 200,00',
                  'Transferências enviadas: R$ 300,00', 'Transferências recebidas: R$ 300,00',
                  'Balanço dos registros selecionados: R$ 800,00', '=synthetic']:
        assert value in basic, value
    assert '=sintético' not in basic, 'Notes leaked while opt-in is off'
    _, filtered = read('pdf-filtered-synthetic.pdf')
    assert 'Balanço dos registros selecionados: R$ -200,00' in filtered
    assert '2 lançamento(s) selecionado(s)' in filtered
    assert 'Todos: internas excluídas' in filtered
    _, without = read('pdf-no-notes-synthetic.pdf')
    assert 'PRIVADO_PDF' not in without and 'FIM_DA_NOTA' not in without
    _, notes = read('pdf-notes-synthetic.pdf')
    assert 'PRIVADO_PDF' in notes and 'FIM_DA_NOTA' in notes, 'Full opt-in note missing'
    assert 'Ação e café' in notes
    assert '<script>texto</script>' in notes, 'PDF must render user text literally'
    assert len(re.findall(r'\btexto\b', notes)) >= 2000, 'Long note truncated'
    reader, many = read('pdf-many-synthetic.pdf')
    assert len(reader.pages) > 20, 'Multipage fixture did not exercise long reports'
    for i in range(650):
        assert f'REGISTRO_{i:04}' in many, i
    print(f'PDF parser OK: totals, notes opt-in, literal text, withdrawal link, filters; {len(reader.pages)} pages / 650 entries without truncation.')


if __name__ == '__main__':
    main()
