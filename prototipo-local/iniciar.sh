#!/usr/bin/env bash
# Calculadora CBS/IBS simplificada - inicia a API oficial da Receita e a tela.
# Requisitos: Java 21+, Node 18+ e Git.
set -euo pipefail
cd "$(dirname "$0")"

[ -f api/pom.xml ] || git clone --depth 1 https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git api
cd api
if [ ! -f calculadora/db/calculadora-pro.db ]; then
  mkdir -p calculadora/db
  ./mvnw -q flyway:migrate -Dflyway.configFiles=./flyway/flyway-pro.conf --batch-mode --errors
fi
[ -f target/api-regime-geral.jar ] || ./mvnw -q clean package -DskipTests --batch-mode
java -Dspring.profiles.active=offline -jar target/api-regime-geral.jar > ../api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID 2>/dev/null' EXIT
cd ..
echo "Aguardando a API subir..."
until curl -s -o /dev/null http://localhost:8080/api/calculadora/dados-abertos/ufs; do sleep 2; done
node server.js
