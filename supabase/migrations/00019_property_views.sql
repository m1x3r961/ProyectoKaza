-- 00019_property_views.sql
-- Add views counter to properties

ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS views_count INT DEFAULT 0;

-- Function to increment views safely (atomic)
CREATE OR REPLACE FUNCTION public.increment_property_view(p_property_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.properties
    SET views_count = views_count + 1
    WHERE id = p_property_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
