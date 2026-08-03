-- =============================================================================
-- KAZA Migration 00010: Extended fields for Publish Screen B04
-- Adds description, amenities, photos, contact info, and extra property fields
-- =============================================================================

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS amenities JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS photos JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS contact_name TEXT,
  ADD COLUMN IF NOT EXISTS contact_phone TEXT,
  ADD COLUMN IF NOT EXISTS age_years INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS floors_total INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS currency_code VARCHAR(3) DEFAULT 'USD',
  ADD COLUMN IF NOT EXISTS highlights JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS operation_subtype VARCHAR(30); -- 'TEMPORAL' para alquiler temporal

-- Asegurar que columnas usadas por el app existen (algunas ya pueden estar)
ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS price_usd NUMERIC(14,2),
  ADD COLUMN IF NOT EXISTS operation VARCHAR(20) DEFAULT 'VENTA',
  ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'PUBLISHED',
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Index para búsquedas rápidas por owner
CREATE INDEX IF NOT EXISTS idx_properties_owner ON public.properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties(status);

-- RLS: El dueño puede ver y editar sus propias propiedades
DROP POLICY IF EXISTS "Owner puede ver sus propiedades" ON public.properties;
CREATE POLICY "Owner puede ver sus propiedades"
ON public.properties FOR ALL
USING (owner_id = auth.uid());

-- Propiedades publicadas son visibles para todos
DROP POLICY IF EXISTS "Propiedades públicas vinculadas" ON public.properties;
CREATE POLICY "Propiedades publicadas son visibles"
ON public.properties FOR SELECT
USING (status IN ('PUBLISHED', 'AVAILABLE'));
