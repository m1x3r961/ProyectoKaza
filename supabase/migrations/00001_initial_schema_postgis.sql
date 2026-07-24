-- =============================================================================
-- KAZA ARCHITECTURE MASTER v0.2 - REFINED ENTERPRISE POSTGRESQL + POSTGIS SCHEMA
-- Migration: 00001_initial_schema_postgis.sql
-- =============================================================================

-- Enable PostGIS & UUID extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. ENUMS
-- -----------------------------------------------------------------------------
CREATE TYPE workspace_type_enum AS ENUM ('PERSONAL', 'ORGANIZATION');
CREATE TYPE asset_scope_enum AS ENUM ('WHOLE_ASSET', 'FULL_FLOOR', 'UNIT', 'COMMERCIAL_SPACE', 'PARTIAL_ASSET');
CREATE TYPE market_cycle_status_enum AS ENUM ('OPEN', 'CLOSURE_CLAIMED', 'CLOSED', 'DISPUTED', 'REVIEW');
CREATE TYPE listing_status_enum AS ENUM ('DRAFT', 'REVIEW', 'AVAILABLE', 'RESERVED', 'CLOSED', 'PAUSED', 'WITHDRAWN', 'STALE', 'SUSPENDED', 'ARCHIVED');
CREATE TYPE pricing_mode_enum AS ENUM ('PUBLIC_NUMERIC', 'CONTACT_FOR_PRICE');
CREATE TYPE promotion_status_enum AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED', 'SUSPENDED');

-- -----------------------------------------------------------------------------
-- 2. WORKSPACES & ORGANIZATIONS (Multi-tenancy Core)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_type workspace_type_enum NOT NULL DEFAULT 'PERSONAL',
    name VARCHAR(255) NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    trust_score NUMERIC(5,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.organization_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_name VARCHAR(50) NOT NULL DEFAULT 'OPERATOR', -- 'ADMIN', 'OPERATOR', 'VIEWER'
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb, -- Fine-grained RBAC + ABAC permissions
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- -----------------------------------------------------------------------------
-- 3. PROPERTIES (Persistencia de Identidad de Activo)
-- Nota: Usamos GEOGRAPHY(Point, 4326) para cálculos métricos exactos (500m, 1km, 5km)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    asset_scope asset_scope_enum NOT NULL DEFAULT 'WHOLE_ASSET',
    
    -- PIN interno declarado y confirmado por publisher (No "oficial/verificado por Kaza")
    canonical_location GEOGRAPHY(Point, 4326) NOT NULL, 
    public_location_mode VARCHAR(20) NOT NULL DEFAULT 'APPROXIMATE', -- 'EXACT' | 'APPROXIMATE'
    public_location_geometry GEOGRAPHY(Point, 4326) NOT NULL,        -- Representación pública generada por backend
    
    country_code VARCHAR(3) NOT NULL,
    city_id VARCHAR(50) NOT NULL,
    address_canonical TEXT,
    property_type VARCHAR(50) NOT NULL,
    
    total_surface_m2 NUMERIC(10,2),
    covered_surface_m2 NUMERIC(10,2),
    rooms INT DEFAULT 0,
    bathrooms INT DEFAULT 0,
    parking_spaces INT DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices geoespaciales GIST sobre tipos GEOGRAPHY
CREATE INDEX IF NOT EXISTS idx_properties_canonical_geog ON public.properties USING GIST (canonical_location);
CREATE INDEX IF NOT EXISTS idx_properties_public_geog ON public.properties USING GIST (public_location_geometry);

-- -----------------------------------------------------------------------------
-- 4. MARKET CYCLES & LISTINGS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.market_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    operation_type VARCHAR(20) NOT NULL, -- 'SALE', 'RENT', 'ANTICRETICO'
    status market_cycle_status_enum NOT NULL DEFAULT 'OPEN',
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    market_cycle_id UUID NOT NULL REFERENCES public.market_cycles(id) ON DELETE CASCADE,
    
    -- Refactorización: Controller es el Workspace (Personal u Organization)
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    operator_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Agente/Operador activo
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    pricing_mode pricing_mode_enum NOT NULL DEFAULT 'PUBLIC_NUMERIC',
    price_original NUMERIC(14,2),
    currency_original VARCHAR(3) DEFAULT 'USD',
    is_negotiable BOOLEAN DEFAULT FALSE,
    
    status listing_status_enum NOT NULL DEFAULT 'DRAFT',
    has_active_promotion BOOLEAN DEFAULT FALSE, -- Campo derivado de ListingPromotions
    
    freshness_confirmed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 5. LISTING PROMOTIONS (Separación estricta de Entitlement PLUS/PRO)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.listing_promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    product_type VARCHAR(50) NOT NULL, -- 'PLUS_MONTHLY', 'PLUS_BOOST'
    payer_user_id UUID NOT NULL REFERENCES auth.users(id),
    source VARCHAR(50) NOT NULL, -- 'APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE_WEB'
    store_transaction_reference VARCHAR(255),
    promotion_context JSONB DEFAULT '{}'::jsonb,
    
    status promotion_status_enum NOT NULL DEFAULT 'ACTIVE',
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 6. PERSISTED MESSAGING & REALTIME
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES auth.users(id),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS) - DEFENSA EN PROFUNDIDAD (READS)
-- -----------------------------------------------------------------------------
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Vistas públicas de lectura en Supabase
CREATE POLICY "Listings disponibles son públicos" 
ON public.listings FOR SELECT 
USING (status = 'AVAILABLE');

CREATE POLICY "Propiedades públicas vinculadas" 
ON public.properties FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.listings l 
        WHERE l.property_id = public.properties.id AND l.status = 'AVAILABLE'
    )
);
