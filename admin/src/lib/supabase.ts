import { createClient } from '@supabase/supabase-js';
export const configured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
export const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321',process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'local-unconfigured');
export async function adminApi(path: string, body?: object) {
 const {data:{session}}=await supabase.auth.getSession();
 if(!session) throw new Error('Inicia sesión.');
 const response=await fetch(`${process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000'}/api/admin${path}`,{method:body?'POST':'GET',headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.access_token}`},...(body?{body:JSON.stringify(body)}:{}),cache:'no-store',signal:AbortSignal.timeout(15000)});
 const data=await response.json();
 if(!response.ok) throw new Error(typeof data.message==='string'?data.message:'No se pudo completar la operación.');
 return data;
}
