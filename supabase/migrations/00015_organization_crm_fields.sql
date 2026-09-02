-- =============================================================================
-- KAZA - U07 (ORGANIZATION BUSINESS)
-- Migration: 00015_organization_crm_fields.sql
-- =============================================================================

-- 1. ADD organization_id TO PROPERTIES
ALTER TABLE public.properties 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;

-- 2. ADD organization_id TO CRM CONTACTS
ALTER TABLE public.crm_contacts 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;

-- 3. ADD organization_id TO CRM OPPORTUNITIES
ALTER TABLE public.crm_opportunities 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;

-- 4. ADD organization_id TO CRM TASKS
ALTER TABLE public.crm_tasks 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;
