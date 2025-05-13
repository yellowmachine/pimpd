const fastify = require('fastify')({ logger: true });
const { exec } = require('child_process');

// Configuración del SSH y seguridad
const SSH_USER = process.env.SSH_USER || 'usuario';
const SSH_HOST = process.env.SSH_HOST || 'servidor.remoto';
const RESTORE_SCRIPT = process.env.RESTORE_SCRIPT || '~/restore.sh';
const AUTH_TOKEN = process.env.RESTORE_TOKEN || 'token-seguro';

fastify.get('/', async (request, reply) => {
  reply.type('text/html').send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Dangerous Restore</title>
        <style>
          body { font-family: sans-serif; margin: 2em; }
          button { background: #d32f2f; color: white; border: none; padding: 1em 2em; font-size: 1.2em; border-radius: 5px; cursor: pointer; }
          #result { margin-top: 1em; font-family: monospace; }
        </style>
      </head>
      <body>
        <h1>Dangerous Restore</h1>
        <button id="restoreBtn">dangerous restore</button>
        <div id="result"></div>
        <script>
          document.getElementById('restoreBtn').onclick = async function() {
            const btn = this;
            btn.disabled = true;
            btn.textContent = 'Restoring...';
            document.getElementById('result').textContent = '';
            try {
              const res = await fetch('/restore', {
                method: 'POST',
                headers: { 'Authorization': 'Bearer ${AUTH_TOKEN}' }
              });
              const data = await res.json();
              document.getElementById('result').textContent = res.ok ? data.result : (data.error || 'Unknown error');
            } catch (e) {
              document.getElementById('result').textContent = 'Network error: ' + e;
            }
            btn.disabled = false;
            btn.textContent = 'dangerous restore';
          };
        </script>
      </body>
    </html>
  `);
});


fastify.post('/restore', async (request, reply) => {
  // Autenticación sencilla por token
  const token = request.headers['authorization'];
  if (token !== `Bearer ${AUTH_TOKEN}`) {
    reply.code(401).send({ error: 'Unauthorized' });
    return;
  }

  // Ejecutar restore.sh por SSH
  const sshCmd = `ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} '${RESTORE_SCRIPT}'`;

  exec(sshCmd, (error, stdout, stderr) => {
    if (error) {
      reply.code(500).send({ error: stderr || error.message });
      return;
    }
    reply.send({ result: stdout.trim() });
  });
});

const start = async () => {
  try {
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();


