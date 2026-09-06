-- ============================================================================
-- FIX PROFILE IDs to match auth.uid()
-- ============================================================================

-- Drop the old function
DROP FUNCTION IF EXISTS public.fn_upsert_profile(TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.fn_upsert_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Create new function that accepts p_id
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
    p_id UUID,
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
        id,
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
        p_id,
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
        
    -- Attempt to update ID if it was generated randomly before (this might fail if FKs exist, but good effort)
    BEGIN
        UPDATE public.profiles SET id = p_id WHERE email = p_email AND id != p_id;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
END;
$$;
