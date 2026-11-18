"""Converte o texto da TIPI oficial (pdftotext -layout do tipi.pdf da Receita) em dados/tipi.json.

Cada linha de NCM da TIPI tem o formato "8471.30.12   descrição ...   0" com a alíquota de IPI (%) na
última coluna: um número (ex.: 0, 3,25, 9,75) ou NT (não tributado). Quando a descrição quebra em
várias linhas, a alíquota pode aparecer em uma linha seguinte; o script procura até 4 linhas adiante.

Uso: python3 ferramentas/tipi.py <tipi.txt> <saida.json> <data>
Sai com código 1 (sem gravar) se o resultado não parecer uma TIPI completa.
"""
import json, re, sys

TXT, SAIDA, DATA = sys.argv[1:4]
linhas = open(TXT, encoding='utf-8', errors='replace').read().splitlines()
COD = re.compile(r'^\s*(\d{4}\.\d{2}\.\d{2})\b(.*)$')
ALIQ_FIM = re.compile(r'\s{2,}(NT|\d{1,3}(?:,\d+)?)\s*$')

aliquotas = {}
for i, linha in enumerate(linhas):
    m = COD.match(linha)
    if not m:
        continue
    codigo = m.group(1).replace('.', '')
    resto = m.group(2)
    a = ALIQ_FIM.search(resto) if resto.strip() else None
    j = i + 1
    while not a and j < len(linhas) and j <= i + 4 and not COD.match(linhas[j]):
        a = ALIQ_FIM.search('  ' + linhas[j])
        j += 1
    if not a:
        continue
    v = a.group(1)
    aliquotas[codigo] = 'NT' if v == 'NT' else float(v.replace(',', '.'))

edicao = next((l.strip() for l in linhas[:400] if re.search(r'Decreto n[ºo°]\s*11\.158', l)), 'TIPI (Decreto nº 11.158/2022 e alterações)')
total = len(aliquotas)
numericas = sum(1 for v in aliquotas.values() if v != 'NT')
print(f'TIPI: {total} NCMs lidas ({numericas} com alíquota numérica, {total - numericas} NT)')
# Conferências mínimas antes de aceitar
problemas = []
if total < 8000:
    problemas.append(f'poucas NCMs lidas ({total})')
if '84713012' not in aliquotas:
    problemas.append('NCM 8471.30.12 (notebook) não encontrada')
if any(v != 'NT' and not (0 <= v <= 400) for v in aliquotas.values()):
    problemas.append('alíquota fora da faixa 0–400%')
if problemas:
    print('TIPI rejeitada: ' + '; '.join(problemas))
    sys.exit(1)

json.dump({
    'fonte': 'TIPI oficial da Receita Federal: https://www.gov.br/receitafederal/pt-br/acesso-a-informacao/legislacao/documentos-e-arquivos/tipi.pdf',
    'edicao': edicao,
    'dataLeitura': DATA,
    'aliquotas': aliquotas,
}, open(SAIDA, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
