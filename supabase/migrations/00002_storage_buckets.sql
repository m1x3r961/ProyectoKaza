-- =============================================================================
-- KAZA MEDIA ENGINE - SUPABASE STORAGE BUCKETS & VERACITY CATEGORIES
-- Migration: 00002_storage_buckets.sql
-- =============================================================================

-- 1. Create Public Bucket for Property Media
INSERT INTO storage.buckets (id, name, public) 
VALUES ('property-photos', 'property-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies for Public Reading
CREATE POLICY "Public Read Property Photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'property-photos');

-- 3. Storage Policies for Authenticated Uploads
CREATE POLICY "Authenticated Users Upload Property Photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'property-photos' 
    AND auth.role() = 'authenticated'
);

-- 4. Create Media Items Table for Listing Content Handover & Veracity
CREATE TYPE media_type_enum AS ENUM (
    'REAL_PHOTO', 
    'EDITED_PHOTO', 
    'RENDER', 
    'AI_CONCEPT', 
    'VIRTUAL_STAGING', 
    'VIDEO', 
    'DRONE', 
    '360', 
    'PLAN', 
    'CONSTRUCTION_PROGRESS'
);

CREATE TABLE IF NOT EXISTS public.listing_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    media_url TEXT NOT NULL,
    media_type media_type_enum NOT NULL DEFAULT 'REAL_PHOTO',
    sort_order INT DEFAULT 0,
    is_canonical_thumbnail BOOLEAN DEFAULT FALSE,
    uploaded_by_user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.listing_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura pública de fotos de listings disponibles"
ON public.listing_media FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.listings l
        WHERE l.id = public.listing_media.listing_id AND l.status = 'AVAILABLE'
    )
);
