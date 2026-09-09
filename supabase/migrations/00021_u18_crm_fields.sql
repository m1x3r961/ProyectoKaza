-- 00021_u18_crm_fields.sql
-- U18 Commercial Cycle (WM-08) CRM Fields Update

-- 1. Update existing default for stage
ALTER TABLE public.crm_opportunities 
  ALTER COLUMN stage SET DEFAULT 'INTERESADO';

-- 2. Migrate any existing stages (if any were created) to the new terminology
UPDATE public.crm_opportunities SET stage = 'INTERESADO' WHERE stage = 'PROSPECTO';
UPDATE public.crm_opportunities SET stage = 'CERRADA' WHERE stage = 'CIERRE';
UPDATE public.crm_opportunities SET stage = 'DESCARTADO' WHERE stage = 'PERDIDO';
-- 'VISITA' and 'NEGOCIACION' remain the same.

-- 3. Add new fields for U18
ALTER TABLE public.crm_opportunities
  ADD COLUMN IF NOT EXISTS interest_level VARCHAR(50) DEFAULT 'NO_CALIFICADO', -- 'ALTO', 'MEDIO', 'BAJO', 'NO_CALIFICADO'
  ADD COLUMN IF NOT EXISTS lead_source VARCHAR(100), -- 'WHATSAPP', 'LLAMADA', 'FORMULARIO', 'REFERIDO', 'CAMPAÑA', 'QR'
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT; -- Reason when stage is DESCARTADO
