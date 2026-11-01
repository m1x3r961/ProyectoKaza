-- ============================================================================
-- 00036 · Bucket para modelos 3D (.glb) de las propiedades
-- ============================================================================
-- property-photos solo admite imagenes de hasta 10 MB (00023), por lo que no
-- puede recibir modelos 3D. Se crea un bucket aparte, publico para lectura,
-- limitado a 50 MB y al tipo model/gltf-binary. Cada usuario solo escribe y
-- borra dentro de su carpeta <uid>/.
-- Aplicar manualmente en Supabase SQL Editor. Idempotente.
-- Reversion: DROP POLICY kaza_models_* ON storage.objects; DELETE FROM storage.buckets WHERE id='property-models';
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('property-models', 'property-models', true, 52428800, ARRAY['model/gltf-binary'])
ON CONFLICT (id) DO UPDATE
  SET public = true, file_size_limit = 52428800, allowed_mime_types = ARRAY['model/gltf-binary'];

DROP POLICY IF EXISTS kaza_models_select ON storage.objects;
DROP POLICY IF EXISTS kaza_models_insert ON storage.objects;
DROP POLICY IF EXISTS kaza_models_delete ON storage.objects;

CREATE POLICY kaza_models_select ON storage.objects FOR SELECT
  USING (bucket_id = 'property-models');

CREATE POLICY kaza_models_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-models'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND kaza_private.active(auth.uid()));

CREATE POLICY kaza_models_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'property-models'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND kaza_private.active(auth.uid()));
