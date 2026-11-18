@echo off
REM Calculadora CBS/IBS simplificada - inicia a API oficial da Receita e a tela.
REM Requisitos: Java 21+, Node 18+ e Git no PATH.
setlocal
cd /d "%~dp0"

if not exist api\pom.xml (
  echo Baixando a API oficial da Receita Federal...
  git clone --depth 1 https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git api || goto erro
)

cd api
if not exist calculadora\db\calculadora-pro.db (
  echo Gerando o banco de dados das regras ^(so na primeira vez^)...
  mkdir calculadora\db 2>nul
  call mvnw.cmd -q flyway:migrate -Dflyway.configFiles=flyway\flyway-pro.conf --batch-mode --errors || goto erro
)
if not exist target\api-regime-geral.jar (
  echo Compilando a API ^(so na primeira vez, leva alguns minutos^)...
  call mvnw.cmd -q clean package -DskipTests --batch-mode || goto erro
)

echo Iniciando a API oficial na porta 8080 ^(janela separada^)...
start "API Receita - porta 8080" java "-Dspring.profiles.active=offline" -jar target\api-regime-geral.jar
cd ..

echo Aguardando a API subir...
:espera
timeout /t 2 /nobreak >nul
curl -s -o nul http://localhost:8080/api/calculadora/dados-abertos/ufs || goto espera

start "" http://localhost:3000
node server.js
goto :eof

:erro
echo.
echo Algo deu errado. Confira se Java 21, Node e Git estao instalados.
pause
