-- =============================================================================
-- KAZA MASTER SCHEMA v0.7 - PROPERTY OWNER AND TITLE
-- Migration: 00008_property_owner_title.sql
-- =============================================================================

-- 1. Add owner_id and title to properties
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS title VARCHAR(255);

-- 2. Update fn_create_property RPC to accept owner_id and title
CREATE OR REPLACE FUNCTION public.fn_create_property(
    p_title TEXT,
    p_property_type VARCHAR,
    p_operation VARCHAR,
    p_price NUMERIC,
    p_surface NUMERIC,
    p_rooms INT,
    p_bathrooms INT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_owner_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_id UUID;
    v_final_title TEXT;
BEGIN
    -- If no title is provided, fallback to the old behavior
    IF p_title IS NULL OR p_title = '' THEN
        v_final_title := COALESCE(p_property_type, 'Propiedad') || ' en ' || p_latitude || ', ' || p_longitude;
    ELSE
        v_final_title := p_title;
    END IF;

    INSERT INTO public.properties (
        title,
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
        status,
        owner_id,
        operation
    ) VALUES (
        v_final_title,
        v_final_title,
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
        'PUBLISHED',
        p_owner_id,
        p_operation
    ) RETURNING id INTO v_property_id;

    RETURN v_property_id;
END;
$$;
