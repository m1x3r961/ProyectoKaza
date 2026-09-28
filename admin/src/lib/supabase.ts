import { createClient } from '@supabase/supabase-js';
export const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
export const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321',process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'local-unconfigured');
export async function adminApi(path: string, body?: object) {
 const base = (process.env.NEXT_PUBLIC_API_BASE_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : '')).trim().replace(/\/+$/, '');
 if (!base) throw new Error('Falta configurar NEXT_PUBLIC_API_BASE_URL en Vercel (admin). Configura la URL del backend y vuelve a desplegar.');
 let url: URL;
 try { url = new URL(base); } catch { throw new Error('NEXT_PUBLIC_API_BASE_URL no es una URL válida.'); }
 if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash
   || (process.env.NODE_ENV === 'production' && (url.protocol !== 'https:' || ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)))) {
  throw new Error('NEXT_PUBLIC_API_BASE_URL debe apuntar al backend público con HTTPS en producción, sin credenciales ni parámetros.');
 }
 const {data:{session}}=await supabase.auth.getSession();
 if(!session) throw new Error('Inicia sesión.');
 let response: Response;
 try {
  response=await fetch(`${base}/api/admin${path}`,{method:body?'POST':'GET',headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.access_token}`},...(body?{body:JSON.stringify(body)}:{}),cache:'no-store',signal:AbortSignal.timeout(15000)});
 } catch {
  throw new Error('No se pudo conectar con el backend. Revisa NEXT_PUBLIC_API_BASE_URL, que el backend esté disponible y que CORS_ORIGINS permita este admin.');
 }
 const data=await response.json().catch(() => { throw new Error(`El backend devolvió una respuesta inesperada (HTTP ${response.status}). Revisa la URL y el despliegue del backend.`); });
 if(!response.ok) throw new Error(typeof data.message==='string'?data.message:'No se pudo completar la operación.');
 return data;
}
