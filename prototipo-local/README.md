# Calculadora CBS/IBS simplificada (protótipo)

Tela simples para calcular CBS e IBS de **um item por vez**, no regime regular.
Quem faz a conta é a **API oficial da Receita Federal**
([calculadora-rtc-regime-regular](https://github.com/ReceitaFederal/calculadora-rtc-regime-regular), licença MIT),
rodando na sua máquina. Esta pasta só adiciona a tela e um servidorzinho que repassa as chamadas.

## Como rodar

Requisitos: **Java 21+**, **Node 18+** e **Git**.

- **Windows:** dê dois cliques em `iniciar.bat`.
- **Linux/macOS:** `./iniciar.sh`

Na primeira vez o script baixa a API da Receita para `api/`, gera o banco de regras e compila
(alguns minutos). Depois abre `http://localhost:3000`.

Para atualizar as regras quando a Receita publicar versão nova: apague a pasta `api/` e rode de novo.

## O que a tela faz

1. Você escolhe **produto (NCM)** ou **serviço (NBS)** e digita o código. A tela mostra a descrição oficial.
2. Escolhe a **classificação tributária (cClassTrib)**, com busca por texto. A tela avisa se ela vale para aquele NCM/NBS
   e mostra a redução de alíquota (ex.: 60% para educação, 100% para alimentos do Anexo I).
3. Informa **valor, data, UF e município** e clica em **Calcular**.
4. Vê CBS, IBS estadual e IBS municipal (alíquota, redução, efetiva, valor), o total, a carga efetiva,
   a memória de cálculo da Receita e o JSON trocado com a API.

Alíquotas: em 2026 (ano de teste) a API usa as de referência oficiais (CBS 0,9% e IBS 0,1%).
Para datas a partir de 2027 ainda não há alíquota oficial cadastrada, então a tela pede as alíquotas para simular.

## Limitações deste protótipo

- Um item por vez; não calcula Imposto Seletivo (avisa quando o NCM está sujeito a ele).
- Não trata Simples Nacional, crédito presumido, diferimento, monofasia nem geração de XML/DANFSe.

## Arquivos

- `public/index.html`: a tela (HTML + JS puro, sem dependências).
- `server.js`: serve a tela na porta 3000 e repassa `/api/*` para a API na porta 8080
  (a API oficial não libera CORS, por isso o repasse). Variáveis: `PORTA`, `API_URL`.
