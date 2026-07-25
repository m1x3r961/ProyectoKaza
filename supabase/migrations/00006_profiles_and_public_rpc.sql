-- =============================================================================
-- KAZA MASTER SCHEMA v0.6 - PROFILES TABLE, POSTGIS PROPERTY RPC & OPEN RLS
-- Migration: 00006_profiles_and_public_rpc.sql
-- =============================================================================

-- 1. TABLA DE PERFILES DE USUARIO Y AGENTE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'USER',
    phone VARCHAR(50),
    license_number VARCHAR(100),
    organization VARCHAR(255),
    zone VARCHAR(255),
    trust_badge_requested BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ASEGURAR COLUMNAS EN TABLA PROPERTIES
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS price_usd NUMERIC(14,2);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'PUBLISHED';
ALTER TABLE public.properties ALTER COLUMN canonical_location DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN public_location_geometry DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN country_code DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN city_id DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN property_type DROP NOT NULL;

-- 3. FUNCIÓN RPC SECURITY DEFINER PARA INSERTAR INMUEBLES DIRECTAMENTE
CREATE OR REPLACE FUNCTION public.fn_create_property(
    p_title TEXT,
    p_property_type VARCHAR,
    p_operation VARCHAR,
    p_price NUMERIC,
    p_surface NUMERIC,
    p_rooms INT,
    p_bathrooms INT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_id UUID;
BEGIN
    INSERT INTO public.properties (
        address_canonical,
        property_type,
        canonical_location,
        public_location_geometry,
        country_code,
        city_id,
        total_surface_m2,
        rooms,
        bathrooms,
        latitude,
        longitude,
        price_usd,
        status
    ) VALUES (
        p_title,
        COALESCE(p_property_type, 'Departamento'),
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
        'BOL',
        'santa_cruz',
        COALESCE(p_surface, 85),
        COALESCE(p_rooms, 2),
        COALESCE(p_bathrooms, 2),
        p_latitude,
        p_longitude,
        p_price,
        'PUBLISHED'
    ) RETURNING id INTO v_property_id;

    RETURN v_property_id;
END;
$$;

-- 4. FUNCIÓN RPC SECURITY DEFINER PARA GUARDAR PERFILES DE USUARIO / AGENTE
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
    p_email TEXT,
    p_full_name TEXT,
    p_role TEXT,
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
        role,
        phone,
        license_number,
        organization,
        zone,
        updated_at
    ) VALUES (
        p_email,
        p_full_name,
        p_role,
        p_phone,
        p_license_number,
        p_organization,
        p_zone,
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        license_number = COALESCE(EXCLUDED.license_number, public.profiles.license_number),
        organization = COALESCE(EXCLUDED.organization, public.profiles.organization),
        zone = COALESCE(EXCLUDED.zone, public.profiles.zone),
        updated_at = NOW();
END;
$$;

-- 5. GRANT PERMISSIONS TO ANON, AUTHENTICATED AND SERVICE_ROLE
GRANT ALL ON TABLE public.profiles TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.properties TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.admin_cases TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.listings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.workspaces TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.messages TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.conversations TO anon, authenticated, service_role;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 6. PERMISOS Y POLITICAS RLS ABIERTAS PARA PROPIEDADES Y PERFILES
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_cases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Properties" ON public.properties;
CREATE POLICY "Public Read Properties" ON public.properties FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Insert Properties" ON public.properties;
CREATE POLICY "Public Insert Properties" ON public.properties FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public Update Properties" ON public.properties;
CREATE POLICY "Public Update Properties" ON public.properties FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Read Profiles" ON public.profiles;
CREATE POLICY "Public Read Profiles" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Insert Profiles" ON public.profiles;
CREATE POLICY "Public Insert Profiles" ON public.profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public Update Profiles" ON public.profiles;
CREATE POLICY "Public Update Profiles" ON public.profiles FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Read Admin Cases" ON public.admin_cases;
CREATE POLICY "Public Read Admin Cases" ON public.admin_cases FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Insert Admin Cases" ON public.admin_cases;
CREATE POLICY "Public Insert Admin Cases" ON public.admin_cases FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public Update Admin Cases" ON public.admin_cases;
CREATE POLICY "Public Update Admin Cases" ON public.admin_cases FOR UPDATE USING (true);
