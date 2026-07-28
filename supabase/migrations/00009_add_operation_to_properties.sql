-- =============================================================================
-- KAZA MASTER SCHEMA v0.7 - ADD OPERATION TO PROPERTIES
-- Migration: 00009_add_operation_to_properties.sql
-- =============================================================================

ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS operation VARCHAR(50) DEFAULT 'VENTA';

-- Refrescar la caché de esquema para PostgREST (usado por Supabase)
NOTIFY pgrst, 'reload schema';
