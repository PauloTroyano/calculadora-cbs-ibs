"""Completa dados/meta.json com a origem e as datas de atualização/verificação.

dataAtualizacao só muda quando alguma tabela (fora o meta.json) mudou de fato.
Uso: atualizar_meta.py <meta anterior> <meta novo> <hoje> <commit oficial> <versão da API>
"""
import json, os, sys, glob, hashlib

ANTERIOR, NOVO, HOJE, COMMIT, VERSAO = sys.argv[1:6]
pasta_nova = os.path.dirname(NOVO)
pasta_ant = os.path.dirname(ANTERIOR)

def resumo(pasta):
    h = hashlib.sha256()
    for f in sorted(glob.glob(os.path.join(pasta, '*.json'))):
        if os.path.basename(f) == 'meta.json':
            continue
        h.update(os.path.basename(f).encode())
        h.update(open(f, 'rb').read())
    return h.hexdigest()

ant = json.load(open(ANTERIOR, encoding='utf-8')) if os.path.exists(ANTERIOR) else {}
novo = json.load(open(NOVO, encoding='utf-8'))
ant_meta_sem_datas = {k: v for k, v in ant.items() if k not in ('dataExportacao', 'dataAtualizacao', 'ultimaVerificacao', 'fonteCommit', 'versaoApi')}
novo_meta_sem_datas = {k: v for k, v in novo.items() if k != 'dataExportacao'}
mudou = resumo(pasta_nova) != resumo(pasta_ant) or ant_meta_sem_datas != novo_meta_sem_datas
novo['fonteCommit'] = COMMIT
novo['versaoApi'] = VERSAO
novo['ultimaVerificacao'] = HOJE
novo['dataAtualizacao'] = HOJE if mudou or 'dataAtualizacao' not in ant else ant['dataAtualizacao']
json.dump(novo, open(NOVO, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print(('Tabelas mudaram' if mudou else 'Tabelas sem mudança') + f"; atualização {novo['dataAtualizacao']}, verificação {HOJE}")
