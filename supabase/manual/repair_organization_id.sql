-- KAZA: reparar columnas organization_id ausentes antes de kaza-upgrade.sql.
-- Ejecutar completo en Supabase SQL Editor como operador.
-- No borra filas ni cambia propietarios. Los registros existentes quedan
-- con organization_id NULL cuando se añade la columna.
-- Si el editor muestra 25P02, ejecutar ROLLBACK; por separado antes de este SQL.

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60s';

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS organization_id UUID
  REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.crm_contacts
  ADD COLUMN IF NOT EXISTS organization_id UUID
  REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.crm_opportunities
  ADD COLUMN IF NOT EXISTS organization_id UUID
  REFERENCES public.organizations(id) ON DELETE SET NULL;

ALTER TABLE public.crm_tasks
  ADD COLUMN IF NOT EXISTS organization_id UUID
  REFERENCES public.organizations(id) ON DELETE SET NULL;

COMMIT;

-- Comprobación: debe devolver cuatro filas con tipo uuid.
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('properties', 'crm_contacts', 'crm_opportunities', 'crm_tasks')
  AND column_name = 'organization_id'
ORDER BY table_name;
