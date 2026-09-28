# Actualizar KAZA: SQL manual + GitHub → Vercel

Este es el flujo acordado: tú ejecutas el SQL en Supabase y publicas el código mediante GitHub. No se aplicaron migraciones remotas ni se hizo push desde esta sesión.

**Actualización del admin (28/09/2026):** acceso con Google y primera cuenta administradora, sin requisito TOTP. Seguir [ADMIN_GOOGLE.md](ADMIN_GOOGLE.md). Para bases con 00023–00026 aplicadas, ejecutar únicamente 00027.

## 1. Preparar las variables en Vercel

Cada aplicación usa su carpeta como **Root Directory**. Si ya existen los proyectos, conservarlos y revisar sus ajustes.

| Proyecto / raíz | Configuración |
| --- | --- |
| Backend / `backend` | Framework NestJS, Node 22; detección nativa desde `src/main.ts`. Quitar overrides históricos de build/output si contradicen la configuración del framework. |
| Admin / `admin` | Framework Next.js, `npm run build`. |
| App / `mobile` | Framework Other; `bash scripts/vercel-build.sh`; salida `build/web`. El script instala Flutter 3.27.0 y compila el código del commit. |

El backend utiliza el soporte actual de [NestJS en Vercel](https://vercel.com/docs/frameworks/backend/nestjs). La configuración anterior de Flutter tenía el build vacío y servía el artefacto ya guardado; ahora los cambios Dart se compilan en cada despliegue. Los archivos viejos de `build/web` no se regeneraron localmente en esta entrega.

**Backend**:

```text
APP_ENV=production
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<solo en backend>
CORS_ORIGINS=https://TU_APP.vercel.app,https://TU_ADMIN.vercel.app
GEMINI_API_KEY=<solo si habilitas el asistente>
GEMINI_MODEL=<modelo disponible en tu cuenta>
```

**Admin**:

```text
NEXT_PUBLIC_SUPABASE_URL=https://TU_PROYECTO.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<clave pública>
NEXT_PUBLIC_API_BASE_URL=https://TU_BACKEND.vercel.app
```

**App Flutter**:

```text
APP_ENV=production
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_ANON_KEY=<clave pública>
API_BASE_URL=https://TU_BACKEND.vercel.app
```

Usar las URL sin barra final. Configurar por separado Preview/Production y los dominios autorizados de Auth. Las variables públicas se incorporan al build: cambiarlas requiere redeploy. Nunca poner `service_role` ni Gemini en variables del frontend. Si solo tienes el frontend desplegado, el flujo nuevo también necesita un proyecto backend accesible.

Para demo, usar un Supabase independiente, `APP_ENV=demo` y declarar `PRODUCTION_SUPABASE_URL` en backend. Las rutas FinTech simuladas devuelven 404 en producción.

## 2. Cargar el SQL manualmente

Primero ejecutar [preflight.sql](../supabase/preflight.sql), que solo inspecciona el esquema. Confirmar que están las migraciones históricas hasta 00022, incluida `u08_desarrolladora.sql`. Tener respaldo y probar en una copia/staging.

Si **00023–00026 aún no están aplicadas**, abrir [kaza-upgrade.sql](../supabase/manual/kaza-upgrade.sql), copiar su contenido completo en SQL Editor y ejecutar como operador. El archivo agrupa, en este orden:

1. `00023_security_baseline.sql`: permisos, perfiles, administradores, borradores, Storage y cuotas verificadas.
2. `00024_listing_commands.sql`: publicación, estados, transferencia, catálogo y moderación.
3. `00025_workflows.sql`: chat, organizaciones, invitaciones y FinTech demo.
4. `00026_integrity_and_realtime.sql`: integridad CRM, listado de conversaciones y consulta de cupos.
5. `00027_google_first_admin.sql`: asignación persistente de la primera cuenta administradora.

El bundle usa una transacción para evitar un esquema aplicado a medias. Si falla, conservar el mensaje y corregir la diferencia de esquema; no saltar líneas ni comentar verificaciones para forzar su ejecución. Si aplicaste parte de estas migraciones anteriormente, no pegar el bundle completo: comparar primero las funciones/tablas existentes. Está pensado para una base histórica reconciliada, no para cualquier esquema remoto.

### Error `42703: column "organization_id" does not exist`

Para corregirlo mediante una carga manual independiente, ejecutar primero [repair_organization_id.sql](../supabase/manual/repair_organization_id.sql). Su consulta final debe devolver cuatro columnas de tipo `uuid`. Después ejecutar el bundle `kaza-upgrade.sql` completo, siempre que el intento anterior no haya sido aplicado parcialmente por separado. El archivo de reparación solo añade las columnas; no aplica por sí mismo las políticas nuevas.

La versión corregida el 28/09/2026 añade `organization_id` como UUID nullable con referencia a `organizations` en `properties`, `crm_contacts`, `crm_opportunities` y `crm_tasks`, antes de crear las políticas. Esto cubre la ausencia de las columnas de `00015_organization_crm_fields.sql`. Los registros existentes conservan su propietario y quedan con organización nula; no se asignan a una organización automáticamente.

Si ejecutaste el bundle completo y falló con ese error, vuelve a abrir el archivo actualizado y ejecuta su contenido completo. La transacción fallida no confirma cambios parciales. Si el editor indica `25P02` (transacción abortada), ejecuta `ROLLBACK;` antes de repetir el bundle. No es necesario borrar tablas ni desactivar RLS. Esta compatibilidad no sustituye la revisión de otras posibles diferencias del esquema.

Para una base nueva, generar `kaza-fresh.sql` con `node backend/scripts/migrations.mjs fresh`; no volver a aplicar migraciones históricas sobre tu base existente.

## 3. Reconciliar datos y administrador

Las propiedades antiguas sin listing necesitan la conversión explícita descrita en [IMPLEMENTACION_SEGURIDAD.md](IMPLEMENTACION_SEGURIDAD.md). Revisar sus datos antes de ejecutar `SELECT public.kaza_backfill_legacy();`. No borra el inventario original; devuelve el número convertido y el pendiente.

La primera cuenta Google que entra al panel queda registrada en `kaza_admins` mediante el servidor. Si ya hay un administrador, se conserva. Ser `ADMIN` en el campo histórico del perfil no concede acceso. Los planes pagados tampoco se importan de valores históricos autoeditables.

## 4. Publicar el commit

Subir los cambios del backend, admin, app, migraciones y documentación a tu rama de despliegue de GitHub. Vercel reconstruye los proyectos conectados. No subir `.env`, credenciales ni el SDK Flutter.

Coordinar una ventana de mantenimiento: el SQL nuevo bloquea escrituras inseguras de los clientes antiguos. Aplicar el SQL y desplegar los tres componentes como una misma entrega, comprobando primero en Preview/staging con base separada.

## 5. Comprobar el despliegue

- Backend `/` y `/health/ready`: respuestas 200.
- Catálogo sin sesión: solo listings disponibles y campos públicos.
- Publicar sin sesión: 401; usuario normal en `/api/admin/dashboard`: 403.
- Publicar, recuperar borrador, guardar, contactar y enviar mensaje con dos usuarios reales.
- Usuario ajeno: sin perfiles privados, CRM, borradores ni mensajes del otro.
- Administrador con Google: moderar con motivo y comprobar registro en `kaza_audit`; una segunda cuenta no obtiene el permiso inicial.
- Al actualizar un estado: mapa y detalle reflejan el estado persistido.

Las pruebas locales no sustituyen estas comprobaciones. El build remoto de Flutter y el despliegue real todavía no se han observado desde esta sesión. El informe de implementación enumera los demás pendientes del plan.
