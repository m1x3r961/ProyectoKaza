# Implementación de flujos y seguridad de KAZA

Actualizado: 27 de septiembre de 2026. Cambios locales; no desplegados ni aplicados a Supabase remoto.

## Alcance implementado

| Área del plan | Cambio en el repositorio | Límite de la verificación |
| --- | --- | --- |
| Identidad | Guard global, token verificado por Supabase Auth, validación de emisor/audiencia/expiración; identidad derivada del token. | Tests de lógica con Auth simulado; falta sesión real en staging. |
| Administración | API con membresía independiente `kaza_admins`, MFA `aal2`, suspensión recuperable y auditoría transaccional. | Build Next.js comprobado; falta enrolamiento MFA real. |
| RLS/RPC | Retirada de políticas heredadas amplias; datos propios o de workspace autorizado; roles/planes no editables por el usuario. | PostgreSQL local con fixtures Auth/Storage; no sustituye pruebas de API Supabase/Realtime. |
| Publicación | Comando atómico property + cycle + listing; idempotencia por actor, clave y payload; control de versión. | Pruebas de rollback, reintento y conflicto; falta concurrencia con varias conexiones reales. |
| Borradores | Autoguardado por usuario, escrituras serializadas, recuperación, reutilización de fotos cargadas y clave de publicación. | Compilación y revisión local; falta recorrido con pérdida de red en navegador/dispositivo. |
| Estados y transferencia | Estados comerciales separados de moderación; transferencia con aceptación, vigencia y permiso del destinatario. | API/SQL disponibles; interfaz completa de transferencias todavía pendiente. |
| Chat | Conversaciones reales por listing, participantes, envío confirmado, identificador de reintento y consulta de los últimos 100 mensajes. | SQL niega terceros y hosts revocados; entrega Realtime aún requiere staging. |
| Organizaciones/CRM | Alta atómica, invitaciones por destinatario, protección de referencias CRM entre usuarios/organizaciones. | No se habilitaron RPC históricas de colaboración sin contrato seguro. |
| Catálogo | API pública acotada por zona, máximo 100 elementos, coordenadas redondeadas y proyección sin dirección privada. | No se ha medido p95 ni carga representativa. |
| IA | Clave y llamada al proveedor solo en backend, timeout, contexto público limitado, sin herramientas de escritura. | Falta probar un modelo disponible con credenciales del entorno. |
| Demo/FinTech | Solo habilitado con `APP_ENV=demo` y URL Supabase distinta a la de producción declarada; transferencias atómicas simuladas; errores de persistencia propagados. | No existe integración bancaria ni cobro real. |
| Operación | Configuración explícita, CORS, límites de solicitudes por proceso, errores seguros, requestId, health/readiness, handler serverless y CI. | Falta ensayo de despliegue, restauración, alertas y límites compartidos. |

Los controles de acceso se comprueban tanto en NestJS como en las funciones SQL que reciben al actor. Las funciones de negocio solo son ejecutables por `service_role`; el navegador no puede elegir `p_actor` y llamarlas directamente. Las lecturas/escrituras directas conservadas usan el JWT del usuario y RLS.

`kaza_admins` y `kaza_entitlements` empiezan vacías. Los antiguos valores de `profiles.system_role` y `subscription_tier` no otorgan privilegios administrativos ni cupos pagados. Un operador debe verificar cualquier alta en esas tablas; no se migran derechos comerciales automáticamente desde campos antes autoeditables.

## Pruebas locales

Resultado de la ejecución del 27/09/2026:

| Comprobación | Resultado |
| --- | --- |
| Backend: compilación, guards, HTTP local, PostgreSQL y bundles | 26 pruebas aprobadas. |
| Admin: build Next.js | Aprobado; comprobación TypeScript posterior también aprobada. |
| Flutter: cliente HTTP y arranque sin configuración | 4 pruebas aprobadas. |
| Flutter: análisis | Sin errores; conserva advertencias y recomendaciones de estilo. |
| `npm audit` backend y admin | 0 hallazgos devueltos por el registro en esta ejecución. |
| Build Flutter web / despliegue Vercel / Supabase remoto | No ejecutados/verificados. |

Desde `backend/`, ejecutar `npm ci` y `npm test`. El comando compila TypeScript y ejecuta pruebas de guards/configuración y PostgreSQL mediante PGlite con PostGIS. Cubre instalación limpia, actualización desde esquema legado, aislamiento, idempotencia, rollback, versiones, CRM, Storage y transferencias simuladas.

La compilación web final no se ejecutó localmente: su solicitud de ejecución fue rechazada. Debe comprobarse en CI/Vercel.

Desde `admin/`, ejecutar `npm ci` y `npm run build`.

Desde `mobile/`, con Flutter 3.27.0 / Dart 3.6.0:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --release --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_ANON_KEY=ci-public-key --dart-define=API_BASE_URL=https://api.example.invalid
```

Ese build usa valores ficticios solo para compilar. No sirve para iniciar sesión ni consultar un entorno real. El análisis conserva advertencias de estilo existentes; los errores de compilación sí hacen fallar CI. El visor de tours separa las importaciones web para permitir pruebas en el runtime nativo.

Las auditorías `npm audit` del backend y admin deben repetirse en CI. Su resultado solo refleja la información del registro en el momento de ejecución; no equivale a una auditoría completa de la aplicación.

## Preparar la base sin alterar el historial remoto

No ejecutar `supabase db push` a ciegas con la carpeta histórica: contiene dos versiones `00015` y dependencias `u08`. `supabase/migration-order.json` define el orden probado y excluye semillas de demostración.

El generador solo escribe archivos locales, no abre conexiones:

```sh
cd backend
node scripts/migrations.mjs fresh
node scripts/migrations.mjs upgrade
```

Produce `supabase/generated/kaza-fresh.sql` y `kaza-upgrade.sql`, ambos con una transacción global, bloqueo de migración y límites de espera. El modo `fresh` incluye el esquema histórico ordenado y los controles nuevos. El modo `upgrade` incluye solamente 00023–00026 y exige la base histórica previamente reconciliada. Se rechaza repetir el endurecimiento ya aplicado.

Requisitos: un proyecto Supabase con sus esquemas `auth` y `storage`, roles habituales y extensión PostGIS disponible. La base PostgreSQL de pruebas contiene sustitutos mínimos de Auth/Storage; no es un proyecto Supabase listo para publicar.

Antes de aplicar en staging:

1. Obtener un respaldo y verificar que puede restaurarse en un entorno aislado.
2. Ejecutar `supabase/preflight.sql` como lectura y contrastar el inventario con el repositorio. Revisar funciones adicionales, políticas Storage y sobrecargas RPC. No exportar filas de negocio al repositorio.
3. Reconciliar columnas, tipos, grants y migraciones ya aplicadas. La comprobación automática de tablas no reemplaza esta comparación.
4. Ensayar el bundle correspondiente sobre una copia de staging. La migración 00023 retira las políticas de las tablas públicas del proyecto y falla si encuentra relaciones ajenas no pertenecientes a extensiones.
5. Verificar catálogo, acciones y permisos con usuarios separados antes de publicar los nuevos clientes. Los clientes antiguos que escriben directamente `properties` dejarán de funcionar; coordinar el cambio con mantenimiento o bloqueo de versiones antiguas.

Con una conexión de operador suministrada fuera del repositorio, `psql` puede aplicar el bundle con `-v ON_ERROR_STOP=1 -f <bundle>`. No incluir contraseñas en comandos versionados ni reutilizar la conexión productiva durante los ensayos. Los bundles no actualizan automáticamente `supabase_migrations.schema_migrations`; registrar esta entrega en el procedimiento de despliegue y reconciliar el historial antes de volver a usar la CLI de Supabase.

### Inventario legado

La migración conserva los registros existentes. Las propiedades antiguas sin `listing` no aparecen en el catálogo nuevo hasta la reconciliación explícita:

```sql
-- Solo operador SQL, tras revisar los datos. No disponible a usuarios ni service_role.
SELECT public.kaza_backfill_legacy();
```

La función crea ciclos/listings para propiedades con dueño Auth activo, conserva fechas y precio declarado y devuelve `migrated`/`unmapped`. Repetirla no duplica listings. Los propietarios inexistentes o suspendidos quedan pendientes. Revisar previamente estados, monedas, derechos de publicación, duplicados e imágenes heredadas: el backfill no acredita procedencia de imágenes ni sanea datos históricos incorrectos.

Las conversaciones antiguas no reciben participantes deducidos automáticamente. Permanecen inaccesibles hasta una migración de participantes basada en evidencia de propiedad/autorización. Nunca abrirlas con una política pública para recuperar compatibilidad.

### Alta inicial del administrador

Crear una cuenta real en Auth, verificar su correo, habilitar TOTP desde el panel y registrar su UUID como operador:

```sql
INSERT INTO public.kaza_admins(user_id) VALUES ('UUID_REAL_DEL_ADMIN');
```

El valor anterior es un marcador que debe reemplazarse. El frontend no permite esta alta. El backend exige tanto esa membresía como una sesión de segundo factor. Para retirar acceso, eliminar la membresía con el procedimiento administrativo de la base; no editar metadata del usuario.

## Configuración y despliegue

Backend: copiar `backend/.env.example` a `.env` y completar URL/clave de servicio. El admin usa `admin/.env.example` con URL y clave pública del mismo proyecto. Flutter recibe `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` y `APP_ENV` mediante `--dart-define`.

`SUPABASE_SERVICE_ROLE_KEY` y `GEMINI_API_KEY` existen únicamente en backend. `CORS_ORIGINS` contiene los orígenes exactos autorizados. Producción requiere HTTPS para Supabase. El modo demo exige `PRODUCTION_SUPABASE_URL` distinta de `SUPABASE_URL`; el operador debe verificar que esa referencia declarada realmente identifica producción.

`GET /` indica vida del proceso; `GET /health/ready` comprueba acceso a una tabla requerida del esquema. El readiness no verifica todas las migraciones, Realtime ni proveedores externos.

Servidor persistente: `npm run build` y `npm run start:prod`. Vercel usa su detección nativa de NestJS con `src/main.ts`; el runtime remoto todavía necesita un ensayo con su configuración real. `src/serverless.ts` queda como adaptador alternativo para hosts basados en handler. El límite de solicitudes en memoria se reinicia con el proceso y no coordina instancias; antes de escalar, agregar un límite en gateway o almacenamiento compartido y definir proxies confiables.

La reversión debe conservar el esquema seguro: corregir hacia adelante o volver a una versión de aplicación compatible. No restaurar políticas abiertas para recuperar funcionalidad. Mantener credenciales y copias de seguridad fuera del repositorio.

## Pendientes reales antes del piloto

- Aplicar y ensayar en staging; MFA/OAuth reales, enlaces directos, expiración de sesión, Realtime, Storage y CORS desde los clientes.
- Persistir la intención de guardar/contactar cuando OAuth recarga toda la página. El callback actual retoma al regresar al mismo navegador/ruta sin recarga; no cubre todas las redirecciones externas.
- Validar borradores con pérdida de red. Las imágenes seleccionadas aún no cargadas solo viven en memoria; las cargadas se recuperan. Las fotos usan un bucket público incluso antes de publicar: no cargar documentos privados. Falta un bucket privado y limpieza controlada de medios huérfanos.
- Completar la experiencia de transferencia de controlador, selección de workspace por identificador y módulos históricos de colaboración/CRM que todavía usan contratos anteriores. Los permisos permanecen cerrados donde no hay un flujo autorizado.
- Ensayar concurrencia real de publicación/estados y el flujo completo mapa → detalle → contacto → mensaje con cuentas independientes.
- Medir p50/p95 con 10.000 listings y 20 usuarios, bytes por respuesta y planes SQL. No se afirma que se hayan alcanzado los objetivos de 800 ms, 2 s o 2,5 s del plan.
- Configurar alertas, cuotas compartidas/costes IA, retención de auditoría y ensayo de restauración. Confirmar responsables de moderación y soporte.

Estos pendientes impiden declarar el plan completo o el sistema listo para producción. El avance local deja controles y contratos verificables sobre los cuales completar el ensayo operativo.
