-- ============================================================================
-- KAZA U09 — PERMISOS PARA DESARROLLADORA
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

GRANT ALL ON public.professional_profiles TO authenticated;
GRANT ALL ON public.professional_profiles TO anon;

GRANT ALL ON public.dev_projects TO authenticated;
GRANT ALL ON public.dev_projects TO anon;

GRANT ALL ON public.dev_project_stages TO authenticated;
GRANT ALL ON public.dev_project_stages TO anon;

GRANT ALL ON public.dev_units TO authenticated;
GRANT ALL ON public.dev_units TO anon;

GRANT ALL ON public.dev_documents TO authenticated;
GRANT ALL ON public.dev_documents TO anon;

GRANT ALL ON public.dev_financial_records TO authenticated;
GRANT ALL ON public.dev_financial_records TO anon;
