-- =============================================================================
-- KAZA ARCHITECTURE: PROFILE SETTINGS (U02)
-- Migration: 00013_profile_settings.sql
-- =============================================================================

-- 1. ADD PROFILE SETTINGS COLUMNS TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS biography TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS location TEXT;

-- 2. CREATE RPC FOR PROFILE SETTINGS UPDATE
CREATE OR REPLACE FUNCTION public.fn_update_profile_settings(
    p_email TEXT,
    p_avatar_url TEXT DEFAULT NULL,
    p_biography TEXT DEFAULT NULL,
    p_location TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET 
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        biography = COALESCE(p_biography, biography),
        location = COALESCE(p_location, location),
        updated_at = NOW()
    WHERE email = p_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_update_profile_settings TO anon, authenticated, service_role;
