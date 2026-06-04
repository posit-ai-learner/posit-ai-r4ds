import { defineConfig, loadEnv } from 'vite';

// A tiny dev-only proxy: the browser calls POST /api/claude, and this middleware
// forwards to the Anthropic API with the key from .env. The key NEVER reaches the
// client. For a deployed build, replace this with a real serverless function.
function claudeProxy(apiKey, model) {
  return {
    name: 'claude-proxy',
    configureServer(server) {
      server.middlewares.use('/api/claude', (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405;
          return res.end('POST only');
        }
        let body = '';
        req.on('data', (c) => (body += c));
        req.on('end', async () => {
          if (!apiKey) {
            res.statusCode = 500;
            return res.end(JSON.stringify({ error: 'ANTHROPIC_API_KEY missing in .env' }));
          }
          try {
            const payload = JSON.parse(body || '{}');
            payload.model = payload.model || model || 'claude-sonnet-4-6';
            payload.max_tokens = payload.max_tokens || 1024;
            const r = await fetch('https://api.anthropic.com/v1/messages', {
              method: 'POST',
              headers: {
                'content-type': 'application/json',
                'x-api-key': apiKey,
                'anthropic-version': '2023-06-01',
              },
              body: JSON.stringify(payload),
            });
            const text = await r.text();
            res.statusCode = r.status;
            res.setHeader('content-type', 'application/json');
            res.end(text);
          } catch (e) {
            res.statusCode = 500;
            res.end(JSON.stringify({ error: String(e) }));
          }
        });
      });
    },
  };
}

export default defineConfig(({ mode }) => {
  // '' prefix => load unprefixed vars (ANTHROPIC_API_KEY) into this config only,
  // not into the client bundle.
  const env = loadEnv(mode, process.cwd(), '');
  return {
    plugins: [claudeProxy(env.ANTHROPIC_API_KEY, env.CLAUDE_MODEL)],
    server: {
      // WebR uses the PostMessage channel, which needs no special headers.
      // To switch to the faster SharedArrayBuffer channel, uncomment these AND
      // update src/webr.js to ChannelType.SharedArrayBuffer:
      // headers: {
      //   'Cross-Origin-Opener-Policy': 'same-origin',
      //   'Cross-Origin-Embedder-Policy': 'require-corp',
      // },
    },
  };
});
