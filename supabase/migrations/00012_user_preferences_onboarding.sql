-- =============================================================================
-- KAZA ARCHITECTURE: ONBOARDING AND USER PREFERENCES (U03)
-- Migration: 00012_user_preferences_onboarding.sql
-- =============================================================================

-- 1. ADD PREFERENCE COLUMNS TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_status VARCHAR(50) DEFAULT 'IN_PROGRESS';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_property_types TEXT[] DEFAULT '{}';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_goals TEXT[] DEFAULT '{}';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_areas TEXT[] DEFAULT '{}';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_notifications JSONB DEFAULT '{"new_properties": true, "price_changes": true, "messages": true}'::jsonb;

-- 2. CREATE RPC FOR ONBOARDING COMPLETION
CREATE OR REPLACE FUNCTION public.fn_complete_onboarding(
    p_email TEXT,
    p_status TEXT,
    p_property_types TEXT[] DEFAULT '{}',
    p_goals TEXT[] DEFAULT '{}',
    p_areas TEXT[] DEFAULT '{}',
    p_notifications JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET 
        onboarding_status = p_status,
        pref_property_types = p_property_types,
        pref_goals = p_goals,
        pref_areas = p_areas,
        pref_notifications = p_notifications,
        updated_at = NOW()
    WHERE email = p_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_complete_onboarding TO anon, authenticated, service_role;
