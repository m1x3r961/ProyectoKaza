# Admin con Google y primera cuenta administradora

Configuración solicitada el 28/09/2026. Sustituye el acceso por contraseña y el requisito TOTP de la entrega anterior.

## Activarlo con SQL manual y GitHub → Vercel

1. Si ya aplicaste 00023–00026, ejecuta únicamente [00027_google_first_admin.sql](../supabase/migrations/00027_google_first_admin.sql) en Supabase SQL Editor. Si todavía no aplicaste el paquete de seguridad, el [bundle actualizado](../supabase/manual/kaza-upgrade.sql) ya incluye 00027; no hace falta aplicarla aparte.
2. En Supabase Auth, conserva Google habilitado y añade `https://proyecto-kaza-admin.vercel.app/` a las Redirect URLs permitidas. El botón vuelve al origen del admin desde el que se inició sesión. Configuración del proveedor: [documentación oficial de Google en Supabase](https://supabase.com/docs/guides/auth/social-login/auth-google).
3. Publica los cambios del **backend y del admin** mediante GitHub. El admin debe tener `NEXT_PUBLIC_API_BASE_URL` apuntando al backend actualizado y el backend debe permitir el dominio del admin en `CORS_ORIGINS`.
4. Abre el panel y pulsa **Continuar con Google**, eligiendo la cuenta que quieres como administradora. Si aún no había ningún administrador registrado, esa cuenta queda asignada y accede al dashboard existente.

## Comportamiento

### Autorizar manualmente a sczkaza@gmail.com

Con 00023–00026 aplicadas, ejecuta completo `supabase/manual/grant_admin_sczkaza.sql` en SQL Editor como postgres. Incluye la configuración de 00027 si falta, dentro de la misma transacción que el alta. Busca una única cuenta existente por correo y añade su UUID a `kaza_admins`. Conserva otros administradores y la marca del primer acceso; repetirlo no duplica permisos ni auditorías. El resultado final debe mostrar el correo autorizado. No se ejecuta desde el navegador ni requiere incluir claves privadas en el admin.

Si la versión anterior del script mostró «Primero aplica las migraciones 00023–00027», vuelve a abrir el archivo actualizado y ejecuta todo su contenido. No hace falta repetir `kaza-upgrade.sql`. Si el editor indica que la transacción está abortada (25P02), ejecuta `ROLLBACK;` y luego el script completo. Si también faltan las dependencias de 00023–00026, el script se detiene sin cambios; este archivo no sustituye esas migraciones.

### Si aparece “Failed to fetch”

Ese mensaje indica un fallo de conexión, no confirma una falta de permisos. El código anterior usaba `localhost:3000` cuando faltaba `NEXT_PUBLIC_API_BASE_URL`; en producción ahora muestra un error de configuración y no intenta esa conexión local.

En el proyecto Vercel del admin, configura `NEXT_PUBLIC_API_BASE_URL` con el origen HTTPS del **backend NestJS**, sin `/api/admin` (no es la URL de Supabase ni de la app pública). Vuelve a desplegar el admin para incorporar la variable al JavaScript. En el backend, `CORS_ORIGINS` debe incluir `https://proyecto-kaza-admin.vercel.app`, conservando los demás orígenes necesarios separados por comas. Autorizar el correo por SQL no repara una conexión fallida.

- La primera sesión Google que completa `POST /api/admin/access` obtiene el permiso. Registrarse solo en la app pública no asigna este rol.
- El UUID de Supabase Auth se registra en `kaza_admins`; una marca única en `kaza_admin_bootstrap` deja constancia del primer administrador. No depende del navegador, de localStorage ni del correo enviado por el cliente.
- Los intentos se serializan en PostgreSQL con un bloqueo común. Dos primeras cuentas no pueden obtener el alta inicial a la vez.
- Cerrar sesión, usar otro navegador o volver a desplegar no cambia al administrador.
- Si ya existía una cuenta en `kaza_admins`, se conserva. La migración no sustituye un administrador existente por la siguiente persona que entre.
- Una cuenta diferente no recibe permisos automáticamente. Se muestra una explicación y puede cambiar de cuenta.
- Retirar el rol del primer administrador no reabre la asignación inicial. Recuperar o cambiar al administrador requiere una intervención explícita del operador de la base.
- El servidor verifica la sesión OAuth de Google y la membresía persistida en cada acción administrativa. El alta inicial tiene auditoría; los usuarios no pueden llamar directamente a la RPC privilegiada.

El dashboard y sus módulos permanecen en `admin/src/app/page.tsx`. La pantalla de acceso usa los mismos colores oscuros y acentos verdes, con estilos propios para no depender de que el dashboard esté montado.

No se ha realizado un login Google real ni aplicado esta migración al proyecto remoto desde esta sesión.

Verificación local: build del backend, build del admin y 9 pruebas de configuración, identidad y asignación inicial aprobados. Las pruebas SQL verifican persistencia, repetición, rechazo de una segunda cuenta y conservación de un administrador existente; no sustituyen un ensayo de OAuth y concurrencia real en Supabase.
