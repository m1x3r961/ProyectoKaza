-- =============================================================================
-- KAZA SEED DATA FOR SUPABASE - SANTA CRUZ, BOLIVIA DEMO
-- Migration / Seed: seed.sql
-- =============================================================================

-- 1. Insert Sample Properties with GEOGRAPHY(Point, 4326)
INSERT INTO public.properties (
    id, asset_scope, canonical_location, public_location_mode, public_location_geometry,
    country_code, city_id, address_canonical, property_type, total_surface_m2, 
    covered_surface_m2, rooms, bathrooms, parking_spaces
) VALUES 
(
    '11111111-1111-1111-1111-111111111111',
    'UNIT',
    ST_SetSRID(ST_MakePoint(-63.1810, -17.7780), 4326)::geography, -- Equipetrol
    'EXACT',
    ST_SetSRID(ST_MakePoint(-63.1810, -17.7780), 4326)::geography,
    'BOL',
    'santa_cruz',
    'Av. San Martín y 4to Anillo, Equipetrol Norte',
    'APARTMENT',
    85.00,
    85.00,
    2,
    2,
    1
),
(
    '22222222-2222-2222-2222-222222222222',
    'WHOLE_ASSET',
    ST_SetSRID(ST_MakePoint(-63.2050, -17.7650), 4326)::geography, -- Urubó
    'APPROXIMATE',
    ST_SetSRID(ST_MakePoint(-63.2050, -17.7650), 4326)::geography,
    'BOL',
    'santa_cruz',
    'Condominio Urubó West, Porongo',
    'HOUSE',
    450.00,
    320.00,
    4,
    4,
    3
),
(
    '33333333-3333-3333-3333-333333333333',
    'COMMERCIAL_SPACE',
    ST_SetSRID(ST_MakePoint(-63.1780, -17.7890), 4326)::geography, -- Sirari
    'EXACT',
    ST_SetSRID(ST_MakePoint(-63.1780, -17.7890), 4326)::geography,
    'BOL',
    'santa_cruz',
    'Calle Los Bosques, Barrio Sirari',
    'OFFICE',
    50.00,
    50.00,
    1,
    1,
    1
);

-- 2. Insert Sample Market Cycles
INSERT INTO public.market_cycles (
    id, property_id, operation_type, status, start_date
) VALUES 
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'SALE', 'OPEN', NOW() - INTERVAL '14 days'),
('a2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'SALE', 'OPEN', NOW() - INTERVAL '42 days'),
('a3333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333', 'RENT', 'OPEN', NOW() - INTERVAL '5 days');
