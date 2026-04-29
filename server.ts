import { Hono } from 'hono';
import { serveStatic } from 'hono/bun';
import { Edge } from 'edge.js';
import { readConfig, upsertAlias, deleteAlias, applyConfig, SUPPORTED_TLDS } from './manager';

const app = new Hono();
const edge = new Edge();

// Mount views directory
edge.mount(new URL('./views', import.meta.url));

// Serve public files like CSS
app.use('/public/*', serveStatic({ root: './' }));

// Helper to extract name and TLD from domain
function extractDomainParts(fullDomain: string) {
  for (const tld of SUPPORTED_TLDS) {
    if (fullDomain.endsWith(tld)) {
      return { name: fullDomain.slice(0, -tld.length), tld };
    }
  }
  const parts = fullDomain.split('.');
  if (parts.length > 1) {
    const ext = '.' + parts.pop();
    return { name: parts.join('.'), tld: ext };
  }
  return { name: fullDomain, tld: '.test' };
}

app.get('/', async (c) => {
  const config = readConfig();
  
  // Transform aliases for view
  const aliases = config.aliases.map((a: any) => ({
    ...a,
    parts: extractDomainParts(a.domain)
  }));

  const html = await edge.render('app', {
    config: { ...config, aliases },
    supportedTlds: SUPPORTED_TLDS,
    url: c.req.url
  });
  return c.html(html);
});

// API endpoints to handle form submissions
app.post('/api/aliases', async (c) => {
  const body = await c.req.parseBody();
  const domain = body.domain as string;
  const tld = body.tld as string;
  const target = body.target as string;
  
  const fullDomain = domain + tld;
  const nextConfig = upsertAlias({
    domain: fullDomain,
    target,
    targetProtocol: 'http', // Default for this simplified version
    skipTlsVerify: false,
    enabled: true
  });
  await applyConfig(nextConfig);
  return c.redirect('/');
});

app.post('/api/aliases/:domain/toggle', async (c) => {
  const domain = c.req.param('domain');
  const config = readConfig();
  const alias = config.aliases.find((a: any) => a.domain === domain);
  if (alias) {
    alias.enabled = !alias.enabled;
    const nextConfig = upsertAlias(alias);
    await applyConfig(nextConfig);
  }
  return c.redirect('/');
});

app.post('/api/aliases/:domain/delete', async (c) => {
  const domain = c.req.param('domain');
  const nextConfig = deleteAlias(domain);
  await applyConfig(nextConfig);
  return c.redirect('/');
});

export default {
  port: 3333,
  fetch: app.fetch,
};
