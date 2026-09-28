'use client';
import React, {useEffect, useState, useRef} from 'react';
import {supabase, configured, adminApi} from '../lib/supabase';
import {Shield, Building2, Users, ArrowRight, LockKeyhole, LogOut} from 'lucide-react';
import styles from './admin-access.module.css';

function GoogleIcon() {
 return <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.6 4.6 0 0 1-1.99 3.02v2.51h3.23c1.89-1.74 2.98-4.3 2.98-7.36Z"/><path fill="#34A853" d="M12 22c2.7 0 4.96-.9 6.62-2.41l-3.23-2.51c-.89.6-2.03.96-3.39.96-2.61 0-4.82-1.76-5.61-4.12H3.05v2.59A10 10 0 0 0 12 22Z"/><path fill="#FBBC05" d="M6.39 13.92a6 6 0 0 1 0-3.84V7.49H3.05a10 10 0 0 0 0 9.02l3.34-2.59Z"/><path fill="#EA4335" d="M12 5.96c1.47 0 2.79.51 3.83 1.51l2.87-2.87A9.62 9.62 0 0 0 12 2a10 10 0 0 0-8.95 5.49l3.34 2.59A5.94 5.94 0 0 1 12 5.96Z"/></svg>;
}

export function AdminAccess({children}:{children:React.ReactNode}) {
 const [allowed,setAllowed]=useState(false);
 const [session,setSession]=useState<string|null>(null);
 const [checking,setChecking]=useState(true);
 const [busy,setBusy]=useState(false);
 const [error,setError]=useState('');
 const [attempt,setAttempt]=useState(0);
 const generation=useRef(0);
 useEffect(()=>{
  let active=true;
  const check=async()=>{
   const version=++generation.current;
   const current=()=>active&&version===generation.current;
   setChecking(true);setError('');setAllowed(false);
   try {
    const {data,error}=await supabase.auth.getSession();
    if(error)throw error;
    if(!current())return;
    setSession(data.session ? data.session.user.email || 'Cuenta de Google' : null);
    if(data.session){await adminApi('/access',{});if(current())setAllowed(true);}
   }catch(error){if(current())setError((error as Error).message);}
   finally{if(current())setChecking(false);}
  };
  if(configured)void check();else setChecking(false);
  const {data:{subscription}}=supabase.auth.onAuthStateChange(()=>{
   generation.current++;setAllowed(false);setChecking(true);
   // Do not await Auth calls inside its event callback.
   setTimeout(()=>{if(active)void check();},0);
  });
  return()=>{active=false;generation.current++;subscription.unsubscribe();};
 },[attempt]);
 async function login(){
  setBusy(true);setError('');
  try{
   const {error}=await supabase.auth.signInWithOAuth({provider:'google',options:{redirectTo:window.location.origin+'/',queryParams:{prompt:'select_account'}}});
   if(error)throw error;
  }catch(error){setError((error as Error).message);}
  finally{setBusy(false);}
 }
 async function logout(){
  generation.current++;setAllowed(false);setBusy(true);setError('');
  try{const {error}=await supabase.auth.signOut({scope:'local'});if(error)throw error;setSession(null);}
  catch(error){setError((error as Error).message);}
  finally{setBusy(false);}
 }
 if(allowed)return <><div className={styles.sessionBar}><span><Shield size={15}/> Administración · {session}</span><button disabled={busy} onClick={logout}><LogOut size={15}/> Cerrar sesión</button></div>{children}</>;
 return (
  <main className={styles.page}>
   <header className={styles.header}>
    <div className={styles.brand}><span className={styles.logo}><Building2 size={24}/></span><span>KAZA<small>BACKOFFICE</small></span></div>
    <span className={styles.badge}><Shield size={14}/> Acceso administrativo</span>
   </header>
   <div className={styles.content}>
    <section className={styles.intro} aria-labelledby="admin-intro">
     <span className={styles.eyebrow}>CENTRO DE ADMINISTRACIÓN</span>
     <h1 id="admin-intro">Todo KAZA.<br/><span>Un solo panel.</span></h1>
     <p>Gestiona tu comunidad, supervisa las publicaciones y da seguimiento a los casos de la plataforma.</p>
     <div className={styles.features}>
      <div><Users size={20}/><span><strong>Usuarios y organizaciones</strong><small>Gestión de cuentas y equipos</small></span></div>
      <div><Building2 size={20}/><span><strong>Contenido y publicaciones</strong><small>Supervisión del catálogo inmobiliario</small></span></div>
      <div><Shield size={20}/><span><strong>Casos y auditoría</strong><small>Seguimiento de las acciones administrativas</small></span></div>
     </div>
    </section>
    <section className={styles.card} aria-labelledby="access-title">
     <span className={styles.lock}><LockKeyhole size={23}/></span>
     <h2 id="access-title">{!configured?'Configuración pendiente':checking?'Comprobando acceso…':session?'Cuenta conectada':'Bienvenido de nuevo'}</h2>
     <p className={styles.subtitle}>{!configured?'Falta completar la conexión de este panel.':session?'Usa la cuenta de Google registrada como administradora.':'Entra con Google para acceder a la administración de KAZA.'}</p>
     {!configured ? <p className={styles.error} role="alert">Configura NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_ANON_KEY en Vercel y vuelve a desplegar el admin.</p> : <>
      {error&&<p role="alert" className={styles.error}>{error}</p>}
      <div className={styles.form} aria-busy={checking||busy}>
       {checking ? <p className={styles.subtitle} role="status">Validando tu sesión de Google…</p> : <>
        {session&&<p className={styles.account}>{session}</p>}
        {!session&&<button className={styles.google} disabled={busy} onClick={login}><GoogleIcon/>{busy?'Abriendo Google…':'Continuar con Google'}<ArrowRight size={18}/></button>}
        {session&&<><button className={styles.primary} disabled={busy} onClick={()=>setAttempt(value=>value+1)}>Reintentar acceso<ArrowRight size={18}/></button><button className={styles.secondary} disabled={busy} onClick={logout}>Usar otra cuenta de Google</button></>}
       </>}
      </div>
      <div className={styles.note}><Shield size={16}/><span>La primera cuenta que acceda queda registrada como administradora. Después, solo las cuentas autorizadas pueden entrar.</span></div>
     </>}

    </section>
   </div>
   <footer className={styles.footer}>KAZA · Consola de administración</footer>
  </main>
 );
}
