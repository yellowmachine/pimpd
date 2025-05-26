const fastify = require('fastify')({ logger: true });
const { exec } = require('child_process');
const multipart = require('@fastify/multipart');
const fs = require('fs');
const path = require('path');
//const { pipeline } = require('stream/promises');
const cors = require('@fastify/cors');


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

fastify.post('/upload', async function (request, reply) {

  console.log('BODY:', request.body);
if (request.body.file) {
  console.log('filePart:', request.body.file);
  console.log('filePart.file:', request.body.file.file);
  console.log('Es stream:', request.body.file.file && typeof request.body.file.file.pipe === 'function');
}


  if (!request.body.base || !request.body.base.value) {
    reply.code(400).send({ error: 'Missing base field' });
    return;
  }
  const base = request.body.base.value;

  const uploadDir = path.join('/app/music', base);
  if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

  const files = [];
  if (request.body.file && request.body.file.file) {
    files.push(request.body.file);
  }
  if (Array.isArray(request.body.files)) {
    files.push(...request.body.files);
  }

  if (files.length === 0) {
      reply.code(400).send({ error: 'No files uploaded' });
      return;
  }

  for (const filePart of files) {
  const dest = path.join(uploadDir, filePart.filename);
  try {
    const buffer = await filePart.toBuffer();
    await fs.promises.writeFile(dest, buffer);
    //await pipeline(filePart.file, fs.createWriteStream(dest));
    const stats = fs.statSync(dest);
    console.log('Tamaño subido:', stats.size);
    if (stats.size === 0) {
      fs.unlinkSync(dest);
      console.error('Archivo vacío:', filePart.filename);
    }
  } catch (err) {
    console.error('Error guardando archivo:', err);
  }
}


  reply.send({ ok: true, files: files.map(f => f.filename) });
});


const start = async () => {
  try {
    await fastify.register(cors, { origin: '*' });
    await fastify.register(multipart, {
      attachFieldsToBody: true,
      limits: {
        fileSize: 1000 * 1024 * 1024 // 50 MB
      }
   });
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();


