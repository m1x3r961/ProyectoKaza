-- 00017_achievements_system.sql
-- KAZA U12-A.1 SISTEMA DE LOGROS (CATÁLOGO MAESTRO)

-- ENUMS
CREATE TYPE achievement_type AS ENUM ('INDIVIDUAL', 'SERIES_MILESTONE', 'COLLECTION', 'META', 'LIMITED_TEMPLATE');
CREATE TYPE achievement_status AS ENUM ('PENDING', 'VALIDATED', 'AWARDED');

-- 1. ACHIEVEMENTS CATALOG (112 Registros Canónicos)
CREATE TABLE public.achievements_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL, -- e.g., 'C001', 'OPS-01.01', 'COL-01'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    achievement_type achievement_type NOT NULL,
    icon_name VARCHAR(100), -- for flutter icon mapping
    color_hex VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. SERIES (Progresión por hitos)
CREATE TABLE public.achievement_series (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    series_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'OPS-01'
    name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Link achievements to series
ALTER TABLE public.achievements_catalog 
ADD COLUMN series_id UUID REFERENCES public.achievement_series(id),
ADD COLUMN milestone_target INTEGER;

-- 3. COLLECTIONS & META-ACHIEVEMENTS
CREATE TABLE public.achievement_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_code VARCHAR(20) UNIQUE NOT NULL, -- 'COL-01'
    name VARCHAR(255) NOT NULL,
    description TEXT
);

ALTER TABLE public.achievements_catalog
ADD COLUMN collection_id UUID REFERENCES public.achievement_collections(id);

-- 4. LIMITED TEMPLATES & EDITIONS
CREATE TABLE public.achievement_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_code VARCHAR(20) UNIQUE NOT NULL, -- 'LT-01'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    base_max_supply INTEGER
);

CREATE TABLE public.achievement_editions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES public.achievement_templates(id) ON DELETE CASCADE,
    edition_name VARCHAR(100) NOT NULL,
    version VARCHAR(20),
    max_supply INTEGER,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. USER ACHIEVEMENTS (The main operational table)
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements_catalog(id) ON DELETE CASCADE,
    edition_id UUID REFERENCES public.achievement_editions(id) ON DELETE SET NULL, -- Only for limited
    status achievement_status DEFAULT 'PENDING',
    award_number INTEGER, -- Sequential per edition
    city_id UUID, -- Optional localization
    timestamp_awarded TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, achievement_id) -- A user can only have one instance of an achievement
);

-- RLS POLICIES
ALTER TABLE public.achievements_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_series ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_editions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- Read policies for public catalogs
CREATE POLICY "Public catalogs are viewable by everyone" ON public.achievements_catalog FOR SELECT USING (true);
CREATE POLICY "Public series are viewable by everyone" ON public.achievement_series FOR SELECT USING (true);
CREATE POLICY "Public collections are viewable by everyone" ON public.achievement_collections FOR SELECT USING (true);
CREATE POLICY "Public templates are viewable by everyone" ON public.achievement_templates FOR SELECT USING (true);
CREATE POLICY "Public editions are viewable by everyone" ON public.achievement_editions FOR SELECT USING (true);

-- User achievements policies (Users can view their own, system manages them)
CREATE POLICY "Users can view their own achievements" ON public.user_achievements
    FOR SELECT USING (auth.uid() = user_id);

-- SEED DATA (MOCK EXAMPLES)
-- Insert a Series
INSERT INTO public.achievement_series (id, series_code, name, description) 
VALUES ('c9a8b7c6-d5e4-f3a2-b1c0-d9e8f7a6b5c4', 'OPS-01', 'Operaciones Realizadas', 'Progresión por volumen de operaciones cerradas');

-- Insert canonical achievements
INSERT INTO public.achievements_catalog (id, code, name, description, achievement_type, icon_name, color_hex, series_id, milestone_target)
VALUES 
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'OPS-01.01', 'Primera Venta', 'Cerraste tu primera operación en KAZA.', 'SERIES_MILESTONE', 'star', '#FFD700', 'c9a8b7c6-d5e4-f3a2-b1c0-d9e8f7a6b5c4', 1),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'OPS-01.02', 'Vendedor Recurrente', 'Has completado 5 operaciones exitosas.', 'SERIES_MILESTONE', 'trending_up', '#C0C0C0', 'c9a8b7c6-d5e4-f3a2-b1c0-d9e8f7a6b5c4', 5),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'IND-01', 'Perfil Perfecto', 'Completaste el 100% de tu perfil KAZA.', 'INDIVIDUAL', 'person_check', '#4CAF50', NULL, NULL),
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', 'IND-02', 'Fotógrafo KAZA', 'Has subido más de 100 fotos en tus propiedades.', 'INDIVIDUAL', 'camera_alt', '#2196F3', NULL, NULL);

