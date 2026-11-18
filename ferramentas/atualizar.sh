#!/usr/bin/env bash
# Atualiza dados/*.json a partir da calculadora oficial da Receita e valida contra a API oficial.
# Só deixa os arquivos novos se a validação passar. Usado pelo workflow diário (.github/workflows/atualizar-tabelas.yml).
#
# Uso: ferramentas/atualizar.sh [pasta de trabalho]
# Requisitos: git, Java 21, Node 18+, Python 3, curl.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TRAB="${1:-$(mktemp -d)}"
API_DIR="$TRAB/calculadora-rtc-regime-regular"
HOJE="$(TZ=America/Sao_Paulo date +%F)"
PORTA="${PORTA:-8080}"

echo "::group::Baixar a calculadora oficial"
if [ ! -d "$API_DIR/.git" ]; then
  git clone --depth 1 https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git "$API_DIR"
fi
COMMIT="$(git -C "$API_DIR" rev-parse HEAD)"
VERSAO_API="$(python3 -c "import re,sys;s=open(sys.argv[1]).read();print(re.search(r'<artifactId>CalculadorTributo</artifactId>\\s*<version>([^<]+)',s).group(1))" "$API_DIR/pom.xml")"
echo "Commit oficial: $COMMIT (versão $VERSAO_API)"
echo "::endgroup::"

echo "::group::Gerar o banco e compilar a API oficial"
cd "$API_DIR"
mkdir -p calculadora/db
[ -f calculadora/db/calculadora-pro.db ] || ./mvnw -q flyway:migrate -Dflyway.configFiles=./flyway/flyway-pro.conf --batch-mode --errors
[ -f target/api-regime-geral.jar ] || ./mvnw -q clean package -DskipTests --batch-mode
echo "::endgroup::"

echo "::group::Subir a API oficial"
java -Dspring.profiles.active=offline -Dserver.port="$PORTA" -jar target/api-regime-geral.jar > "$TRAB/api.log" 2>&1 &
API_PID=$!
trap 'kill $API_PID 2>/dev/null || true' EXIT
for i in $(seq 1 90); do
  curl -sf -o /dev/null "http://localhost:$PORTA/api/calculadora/dados-abertos/ufs" && break
  sleep 2
  [ "$i" = 90 ] && { echo "A API não subiu"; tail -50 "$TRAB/api.log"; exit 1; }
done
echo "::endgroup::"

cd "$RAIZ"
cp -r dados "$TRAB/dados-anterior"
ANTES_NAO_SUPORTADAS="$(node -e "console.log(require('./dados/classes.json').filter(c=>!c.suportado).length)")"

echo "::group::Exportar as tabelas ($HOJE)"
python3 ferramentas/exportar.py "$API_DIR/calculadora/db/calculadora-pro.db" "http://localhost:$PORTA" "$HOJE"
echo "::endgroup::"

echo "::group::Validar contra a API oficial"
falhou=0
node ferramentas/validar.js "http://localhost:$PORTA" --gravar > "$TRAB/validacao-gravar.txt" || true
grep -v '^  NS' "$TRAB/validacao-gravar.txt" || true
node ferramentas/validar.js "http://localhost:$PORTA" > "$TRAB/validacao.txt" || falhou=1
grep -v '^  NS' "$TRAB/validacao.txt"
DEPOIS_NAO_SUPORTADAS="$(node -e "console.log(require('./dados/classes.json').filter(c=>!c.suportado).length)")"
echo "Classificações não calculadas: antes $ANTES_NAO_SUPORTADAS, agora $DEPOIS_NAO_SUPORTADAS"
# Se a conta do navegador passou a divergir em classificações que antes funcionavam, não publica
if [ "$DEPOIS_NAO_SUPORTADAS" -gt "$ANTES_NAO_SUPORTADAS" ]; then
  echo "::error::Mais classificações deixaram de bater com a API oficial ($ANTES_NAO_SUPORTADAS -> $DEPOIS_NAO_SUPORTADAS). Revisar calc.js antes de publicar."
  falhou=1
fi
echo "::endgroup::"

if [ "$falhou" = 1 ]; then
  echo "::error::Validação falhou. As tabelas antigas foram mantidas."
  rm -rf dados && cp -r "$TRAB/dados-anterior" dados
  exit 1
fi

python3 ferramentas/atualizar_meta.py "$TRAB/dados-anterior/meta.json" dados/meta.json "$HOJE" "$COMMIT" "$VERSAO_API"
echo "Atualização concluída."
