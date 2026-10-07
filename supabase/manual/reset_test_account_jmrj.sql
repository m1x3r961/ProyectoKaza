-- Solo para reiniciar la cuenta de prueba jmrj.961@gmail.com.
-- Primero ejecutar con apply_reset=false para revisar el resultado.
-- Después cambiar a true y ejecutar completo. El borrado es permanente.
-- No incluir este archivo en migraciones ni en kaza-upgrade.sql.
BEGIN;
SET LOCAL lock_timeout = '10s';
DO $$
DECLARE
 apply_reset boolean := false;
 target_id uuid;
 matches integer;
 related_count bigint;
 dependency record;
BEGIN
 SELECT count(*) INTO matches FROM auth.users WHERE lower(email)='jmrj.961@gmail.com';
 IF matches <> 1 THEN RAISE EXCEPTION 'Se esperaba exactamente una cuenta jmrj.961@gmail.com; encontradas: %', matches; END IF;
 SELECT id INTO target_id FROM auth.users WHERE lower(email)='jmrj.961@gmail.com' FOR UPDATE;
 PERFORM pg_advisory_xact_lock(71629349);
 IF EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=target_id)
 OR EXISTS(SELECT 1 FROM public.kaza_admin_bootstrap WHERE user_id=target_id) THEN
  RAISE EXCEPTION 'No se puede reiniciar una cuenta administradora.';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=target_id AND status='DELETED') THEN
  RAISE EXCEPTION 'Este reinicio requiere que la cuenta esté dada de baja (DELETED).';
 END IF;

 -- No eliminar propiedades, espacios, equipos, chats ni otros datos relacionados.
 -- Cualquier relación pública adicional exige revisar su alcance por separado.
 FOR dependency IN
  SELECT ns.nspname AS schema_name, tbl.relname AS table_name, col.attname AS column_name
  FROM pg_constraint fk
  JOIN pg_class tbl ON tbl.oid=fk.conrelid
  JOIN pg_namespace ns ON ns.oid=tbl.relnamespace
  JOIN pg_attribute col ON col.attrelid=tbl.oid AND col.attnum=ANY(fk.conkey)
  WHERE fk.contype='f' AND ns.nspname='public'
   AND fk.confrelid IN ('auth.users'::regclass,'public.profiles'::regclass)
 LOOP
  EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I::text=$1',dependency.schema_name,dependency.table_name,dependency.column_name)
   INTO related_count USING target_id::text;
  IF related_count > 0 THEN
   RAISE EXCEPTION 'Hay % registros relacionados en %. No se borró nada; revisar esos datos antes de reiniciar.',related_count,dependency.table_name;
  END IF;
 END LOOP;

 -- Storage requiere su API para borrar archivos físicos; no borrar metadatos SQL.
 FOR dependency IN
  SELECT column_name FROM information_schema.columns
  WHERE table_schema='storage' AND table_name='objects' AND column_name IN ('owner','owner_id')
 LOOP
  EXECUTE format('SELECT count(*) FROM storage.objects WHERE %I::text=$1',dependency.column_name)
   INTO related_count USING target_id::text;
  IF related_count > 0 THEN RAISE EXCEPTION 'La cuenta tiene archivos en Storage. Retíralos mediante Storage antes de reiniciar; no se borró nada.'; END IF;
 END LOOP;
 SELECT count(*) INTO related_count FROM storage.objects
 WHERE split_part(name,'/',1) IN (target_id::text,'jmrj.961@gmail.com');
 IF related_count > 0 THEN RAISE EXCEPTION 'Hay archivos en la carpeta de la cuenta. Retíralos mediante Storage antes de reiniciar; no se borró nada.'; END IF;

 IF NOT apply_reset THEN
  RAISE NOTICE 'REVISIÓN OK: correo jmrj.961@gmail.com, UUID %. Se borrarán su perfil y su cuenta Auth (incluidas sesiones e identidades vinculadas). La auditoría se conserva. Cambia apply_reset a true para aplicar.',target_id;
  RETURN;
 END IF;
 INSERT INTO public.kaza_audit(actor,action,target,reason)
 VALUES(target_id,'manual_test_account_reset',target_id,'Reinicio de prueba solicitado por el propietario; ejecutado por operador SQL ' || session_user || '. Actor identifica el destinatario, no una sesión del usuario.');
 DELETE FROM public.profiles WHERE id=target_id;
 DELETE FROM auth.users WHERE id=target_id;
 RAISE NOTICE 'Reinicio completado para jmrj.961@gmail.com. Cierra sesión y regístrate con Google para obtener una cuenta nueva.';
END $$;
COMMIT;
SELECT u.id,u.email,p.status FROM auth.users u LEFT JOIN public.profiles p ON p.id=u.id
WHERE lower(u.email)='jmrj.961@gmail.com';
