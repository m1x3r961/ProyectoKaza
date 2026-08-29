-- =============================================================================
-- KAZA ARCHITECTURE: ALIGN USER AND AGENT ROLES
-- Migration: 00011_align_user_architecture.sql
-- =============================================================================

-- 1. ADD NEW COLUMNS TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS system_role VARCHAR(50) DEFAULT 'USER';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_agent BOOLEAN DEFAULT FALSE;

-- 2. MIGRATE DATA FROM OLD `role` COLUMN TO NEW COLUMNS
UPDATE public.profiles
SET 
    system_role = CASE 
        WHEN role = 'ADMIN' THEN 'ADMIN'
        WHEN role = 'MODERATOR' THEN 'MODERATOR'
        WHEN role = 'SUPPORT' THEN 'SUPPORT'
        ELSE 'USER'
    END,
    is_agent = CASE 
        WHEN role = 'AGENT' THEN TRUE 
        ELSE FALSE 
    END;

-- 3. DROP OLD COLUMN
ALTER TABLE public.profiles DROP COLUMN role;

-- 4. UPDATE fn_upsert_profile RPC
-- Drop the old function since the signature changes
DROP FUNCTION IF EXISTS public.fn_upsert_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
    p_email TEXT,
    p_full_name TEXT,
    p_system_role TEXT DEFAULT 'USER',
    p_is_agent BOOLEAN DEFAULT FALSE,
    p_phone TEXT DEFAULT NULL,
    p_license_number TEXT DEFAULT NULL,
    p_organization TEXT DEFAULT NULL,
    p_zone TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (
        email,
        full_name,
        system_role,
        is_agent,
        phone,
        license_number,
        organization,
        zone,
        updated_at
    ) VALUES (
        p_email,
        p_full_name,
        p_system_role,
        p_is_agent,
        p_phone,
        p_license_number,
        p_organization,
        p_zone,
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        system_role = EXCLUDED.system_role,
        is_agent = EXCLUDED.is_agent,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        license_number = COALESCE(EXCLUDED.license_number, public.profiles.license_number),
        organization = COALESCE(EXCLUDED.organization, public.profiles.organization),
        zone = COALESCE(EXCLUDED.zone, public.profiles.zone),
        updated_at = NOW();
END;
$$;
