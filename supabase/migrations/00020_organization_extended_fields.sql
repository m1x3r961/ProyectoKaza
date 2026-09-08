-- =============================================================================
-- KAZA MASTER SCHEMA - ORGANIZATION EXTENDED FIELDS FOR CRM
-- Migration: 00020_organization_extended_fields.sql
-- =============================================================================

-- ADD extended fields for organization CRM profile
ALTER TABLE public.organizations
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS logo_url VARCHAR(255),
    ADD COLUMN IF NOT EXISTS website VARCHAR(255),
    ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(50),
    ADD COLUMN IF NOT EXISTS city VARCHAR(100),
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS org_type VARCHAR(50) DEFAULT 'DEVELOPER'; -- 'DEVELOPER', 'AGENCY', 'PRO_AGENT'

-- Create indexes for performance on these fields if they might be searched
CREATE INDEX IF NOT EXISTS idx_organizations_type ON public.organizations(org_type);
CREATE INDEX IF NOT EXISTS idx_organizations_city ON public.organizations(city);
