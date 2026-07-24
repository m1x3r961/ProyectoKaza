-- =============================================================================
-- KAZA SPATIAL ENGINE - POSTGIS POLYGON & RADIUS SEARCH FUNCTIONS
-- Migration: 00003_postgis_spatial_functions.sql
-- =============================================================================

-- 1. Búsqueda por Radio Exacto en Metros (500m, 1km, 2km, 5km)
CREATE OR REPLACE FUNCTION public.fn_search_properties_near_radius(
    p_longitude NUMERIC,
    p_latitude NUMERIC,
    p_radius_meters NUMERIC DEFAULT 1000
)
RETURNS TABLE (
    id UUID,
    property_type VARCHAR,
    address_canonical TEXT,
    distance_meters NUMERIC,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.property_type,
        p.address_canonical,
        ST_Distance(
            p.canonical_location, 
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        )::NUMERIC AS distance_meters,
        ST_Y(p.public_location_geometry::geometry) AS latitude,
        ST_X(p.public_location_geometry::geometry) AS longitude
    FROM public.properties p
    WHERE ST_DWithin(
        p.canonical_location, 
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography, 
        p_radius_meters
    )
    ORDER BY distance_meters ASC;
END;
$$;

-- 2. Búsqueda por Polígono Personalizado Dibujado por el Usuario
CREATE OR REPLACE FUNCTION public.fn_search_properties_in_polygon(
    p_polygon_wkt TEXT
)
RETURNS TABLE (
    id UUID,
    property_type VARCHAR,
    address_canonical TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.property_type,
        p.address_canonical,
        ST_Y(p.public_location_geometry::geometry) AS latitude,
        ST_X(p.public_location_geometry::geometry) AS longitude
    FROM public.properties p
    WHERE ST_Contains(
        ST_GeomFromText(p_polygon_wkt, 4326)::geography,
        p.canonical_location
    );
END;
$$;
