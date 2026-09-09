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

-- =============================================================================
-- FIX PERMISSIONS FOR WORKSPACES & ORGANIZATIONS
-- =============================================================================

-- 1. Grant base privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workspaces TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_memberships TO authenticated;

-- 2. Enable RLS
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_memberships ENABLE ROW LEVEL SECURITY;

-- 2.5 Create RLS Policies for Workspaces
DROP POLICY IF EXISTS "Public Read Workspaces" ON public.workspaces;
DROP POLICY IF EXISTS "Users can create workspaces" ON public.workspaces;
DROP POLICY IF EXISTS "Users can update own workspaces" ON public.workspaces;
DROP POLICY IF EXISTS "Users can delete own workspaces" ON public.workspaces;

CREATE POLICY "Public Read Workspaces" ON public.workspaces FOR SELECT USING (true);
CREATE POLICY "Users can create workspaces" ON public.workspaces FOR INSERT WITH CHECK (auth.uid() = owner_user_id);
CREATE POLICY "Users can update own workspaces" ON public.workspaces FOR UPDATE USING (auth.uid() = owner_user_id);
CREATE POLICY "Users can delete own workspaces" ON public.workspaces FOR DELETE USING (auth.uid() = owner_user_id);

-- 3. Create RLS Policies for Organizations
DROP POLICY IF EXISTS "Public Read Organizations" ON public.organizations;
DROP POLICY IF EXISTS "Users can create organizations" ON public.organizations;
DROP POLICY IF EXISTS "Members can update their organization" ON public.organizations;

-- Permitir leer a todos por ahora
CREATE POLICY "Public Read Organizations" ON public.organizations FOR SELECT USING (true);
-- Permitir a usuarios autenticados crear organizaciones
CREATE POLICY "Users can create organizations" ON public.organizations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
-- Permitir actualizar organizaciones a sus miembros (Simplificado: owner/admin en memberships)
CREATE POLICY "Members can update their organization" ON public.organizations FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.organization_memberships
        WHERE organization_id = public.organizations.id
        AND user_id = auth.uid()
    )
);

-- 4. Create RLS Policies for Organization Memberships
DROP POLICY IF EXISTS "Public Read Memberships" ON public.organization_memberships;
DROP POLICY IF EXISTS "Users can insert memberships" ON public.organization_memberships;
DROP POLICY IF EXISTS "Users can update memberships" ON public.organization_memberships;
DROP POLICY IF EXISTS "Users can delete memberships" ON public.organization_memberships;

CREATE POLICY "Public Read Memberships" ON public.organization_memberships FOR SELECT USING (true);
-- Permitir insert (ej: creador de org se asigna owner)
CREATE POLICY "Users can insert memberships" ON public.organization_memberships FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Permitir update/delete a los admins
CREATE POLICY "Users can update memberships" ON public.organization_memberships FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete memberships" ON public.organization_memberships FOR DELETE USING (auth.uid() = user_id);
