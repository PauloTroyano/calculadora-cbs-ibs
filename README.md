# Calculadora CBS/IBS simplificada

Calculadora da Reforma Tributária do Consumo (CBS e IBS, LC 214/2025) para **um item por vez, no regime regular**.
Roda inteira no navegador, publicada no GitHub Pages: **https://paulotroyano.github.io/calculadora-cbs-ibs/**

As regras e tabelas vêm da calculadora oficial da Receita Federal,
[calculadora-rtc-regime-regular](https://github.com/ReceitaFederal/calculadora-rtc-regime-regular) (licença MIT).

## Como funciona

1. `ferramentas/exportar.py` lê o banco oficial (`calculadora-pro.db`) e a API oficial rodando localmente e gera `dados/*.json`:
   classificações tributárias (cClassTrib) com reduções, anexos de NCM/NBS e exceções, tabelas NCM/NBS, UFs/municípios e alíquotas de referência.
2. `calc.js` faz a conta no navegador: `base × alíquota × (1 − redução)`, com a mesma regra de vínculo NCM/NBS × classificação
   da `NcmAplicavelService` oficial, diferimento e situações sem destaque (isenção, imunidade etc.).
3. `ferramentas/validar.js` compara `calc.js` com a API oficial em todas as classificações (datas de 2026 com alíquota de referência
   e 2027 com alíquotas simuladas) e numa amostra de 600 vínculos NCM/NBS. Com `--gravar`, marca como "não calculada"
   cada classificação em que o resultado não bate.

Resultado da última validação: 328 cálculos iguais, 0 diferentes; 600 vínculos iguais, 0 diferentes.

## O que ainda não calcula

- Imposto Seletivo, monofasia de combustíveis, alíquotas fixas/setoriais específicas e classificações que exigem dados extras da operação.
  Elas aparecem na lista com "(não calculada)" e o motivo.
- Para datas a partir de 2027 ainda não há alíquota oficial de referência: a página pede as alíquotas para simular.

## Atualizar as tabelas quando a Receita publicar nova versão

```bash
git clone --depth 1 https://github.com/ReceitaFederal/calculadora-rtc-regime-regular api && cd api
mkdir -p calculadora/db && ./mvnw flyway:migrate -Dflyway.configFiles=./flyway/flyway-pro.conf
./mvnw clean package -DskipTests && java -Dspring.profiles.active=offline -jar target/api-regime-geral.jar &
cd ..
python3 ferramentas/exportar.py api/calculadora/db/calculadora-pro.db http://localhost:8080 $(date +%F)
node ferramentas/validar.js --gravar && node ferramentas/validar.js
```

## Versão local com a API oficial

A pasta `prototipo-local/` tem a primeira versão, que chama a API oficial rodando no seu computador (Java 21 + Node).
Veja o README dela.

---
Protótipo, não substitui orientação contábil.
