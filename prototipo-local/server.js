// Servidor mínimo: entrega a tela (public/) e repassa /api/* para a API oficial da Receita.
// Sem dependências: só Node 18+.
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORTA = Number(process.env.PORTA || 3000);
const API = new URL(process.env.API_URL || 'http://localhost:8080');
const PUBLICO = path.join(__dirname, 'public');
const TIPOS = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css' };

http.createServer((req, res) => {
  if (req.url.startsWith('/api/')) {
    const proxy = http.request({
      hostname: API.hostname, port: API.port, path: req.url, method: req.method,
      headers: { 'content-type': req.headers['content-type'] || 'application/json', accept: 'application/json' },
    }, (r) => { res.writeHead(r.statusCode, { 'content-type': r.headers['content-type'] || 'application/json' }); r.pipe(res); });
    proxy.on('error', () => {
      res.writeHead(502, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ title: 'API oficial fora do ar', detail: `Não consegui falar com ${API.origin}. Ela está rodando?` }));
    });
    return req.pipe(proxy);
  }
  const arquivo = path.join(PUBLICO, path.normalize(req.url.split('?')[0] === '/' ? '/index.html' : req.url.split('?')[0]));
  if (!arquivo.startsWith(PUBLICO)) { res.writeHead(403); return res.end(); }
  fs.readFile(arquivo, (err, dados) => {
    if (err) { res.writeHead(404); return res.end('Não encontrado'); }
    res.writeHead(200, { 'content-type': TIPOS[path.extname(arquivo)] || 'application/octet-stream' });
    res.end(dados);
  });
}).listen(PORTA, () => console.log(`Calculadora em http://localhost:${PORTA} (API: ${API.origin})`));
