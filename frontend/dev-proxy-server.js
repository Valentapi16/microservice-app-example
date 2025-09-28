const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const port = 3000;

// Configurar proxies para las APIs
app.use('/login', createProxyMiddleware({
  target: 'http://localhost:8082',
  changeOrigin: true,
  secure: false
}));

app.use('/todos', createProxyMiddleware({
  target: 'http://localhost:8083',
  changeOrigin: true,
  secure: false
}));

// Servir archivos estáticos del directorio dist
app.use(express.static('./dist'));

// Fallback para SPA - devolver index.html para todas las rutas no encontradas
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

app.listen(port, () => {
  console.log(`Frontend server running on http://localhost:${port}`);
  console.log('Proxies configured:');
  console.log('- /login -> http://localhost:8082');
  console.log('- /todos -> http://localhost:8083');
});