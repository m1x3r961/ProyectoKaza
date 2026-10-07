export function configuration(env: NodeJS.ProcessEnv = process.env) {
  const mode = env.APP_ENV || 'development';
  if (!['development', 'demo', 'production', 'test'].includes(mode)) throw new Error('Invalid APP_ENV');
  const required = (key: string) => { const value = env[key]?.trim(); if (!value || value.includes('PLACEHOLDER')) throw new Error(`Missing ${key}`); return value; };
  const url = required('SUPABASE_URL');
  const apiUrl = new URL(url);
  if (mode === 'production' && apiUrl.protocol !== 'https:') throw new Error('SUPABASE_URL must use HTTPS');
  const origins = (env.CORS_ORIGINS || (mode === 'production' ? '' : 'http://localhost:3001,http://localhost:8080')).split(',').map(v => v.trim()).filter(Boolean);
  if (!origins.length || origins.includes('*')) throw new Error('Explicit CORS_ORIGINS required');
  const productionRef = env.PRODUCTION_SUPABASE_URL;
  if (mode === 'demo' && (!productionRef || new URL(productionRef).origin === apiUrl.origin)) throw new Error('Demo requires a different Supabase project and PRODUCTION_SUPABASE_URL');
  return { mode, url: url.replace(/\/$/, ''), serviceKey: required('SUPABASE_SERVICE_ROLE_KEY'), origins,
    port: Number(env.PORT || 3000), demo: mode === 'demo', geminiKey: env.GEMINI_API_KEY,
    geminiModel: env.GEMINI_MODEL || 'gemini-1.5-flash' };
}
