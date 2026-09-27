-- Read-only schema inventory. Does not select business data or change permissions.
SELECT table_schema,table_name,column_name,data_type,is_nullable
FROM information_schema.columns WHERE table_schema='public'
ORDER BY table_name,ordinal_position;

SELECT schemaname,tablename,policyname,roles,cmd,qual,with_check
FROM pg_policies WHERE schemaname IN ('public','storage')
ORDER BY schemaname,tablename,policyname;

SELECT grantee,table_schema,table_name,privilege_type
FROM information_schema.role_table_grants WHERE table_schema IN ('public','storage')
ORDER BY table_schema,table_name,grantee,privilege_type;

SELECT p.oid::regprocedure AS signature,p.prosecdef AS security_definer,p.proconfig,p.proacl
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname IN ('public','kaza_private')
AND NOT EXISTS(SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass AND d.objid=p.oid AND d.deptype='e')
ORDER BY p.oid::regprocedure::text;

SELECT schemaname,tablename,indexname,indexdef FROM pg_indexes
WHERE schemaname='public' ORDER BY tablename,indexname;
