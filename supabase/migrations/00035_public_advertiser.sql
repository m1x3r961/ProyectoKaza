-- ============================================================================
-- 00035 · Anunciante real en la ficha pública
-- ============================================================================
-- La ficha mostraba un anunciante de ejemplo porque el catálogo no exponía
-- quién publica. Se agrega un bloque "advertiser" SOLO en el detalle, con datos
-- públicos y coherentes con la política de privacidad:
--   * Organización: nombre, logo, descripción y verificación de la empresa.
--   * Particular: solo el nombre de contacto que la persona eligió mostrar.
--   * Ambos: año de alta del espacio y cantidad de publicaciones activas.
-- Nunca se expone correo, teléfono personal ni el id del usuario.
-- Aplicar manualmente en Supabase SQL Editor. Idempotente.
-- ============================================================================

CREATE OR REPLACE FUNCTION kaza_private.public_advertiser(l public.listings, p public.properties)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT jsonb_build_object(
    'kind', CASE WHEN o.id IS NOT NULL THEN 'ORGANIZATION' ELSE 'PERSONAL' END,
    'name', CASE WHEN o.id IS NOT NULL THEN o.legal_name
                 WHEN p.show_contact THEN NULLIF(btrim(p.contact_name), '')
                 ELSE NULL END,
    'logo_url', o.logo_url,
    'description', o.description,
    'is_verified', COALESCE(o.is_verified, false),
    'member_since', to_char(w.created_at, 'YYYY'),
    'active_listings', (
      SELECT count(*) FROM public.listings x
      WHERE x.workspace_id = l.workspace_id
        AND x.status = 'AVAILABLE' AND x.moderation_status = 'APPROVED')
  )
  FROM public.workspaces w
  LEFT JOIN public.organizations o ON o.workspace_id = w.id AND w.workspace_type = 'ORGANIZATION'
  WHERE w.id = l.workspace_id;
$$;

CREATE OR REPLACE FUNCTION kaza_private.public_listing(l public.listings,p public.properties,p_detail boolean DEFAULT false) RETURNS jsonb LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT jsonb_build_object('id',p.id,'listing_id',l.id,'title',l.title,'price_usd',CASE WHEN l.pricing_mode='PUBLIC_NUMERIC' THEN l.price_original ELSE NULL END,'currency_code',l.currency_original,'operation',CASE c.operation_type WHEN 'SALE' THEN 'VENTA' WHEN 'RENT' THEN 'ALQUILER' ELSE c.operation_type END,'property_type',p.property_type,'latitude',round(p.latitude::numeric,3),'longitude',round(p.longitude::numeric,3),'public_location_mode','APPROXIMATE','rooms',p.rooms,'bathrooms',p.bathrooms,'total_surface_m2',p.total_surface_m2,'photos',CASE WHEN p_detail THEN coalesce(p.photos,'[]') ELSE CASE WHEN jsonb_array_length(coalesce(p.photos,'[]'))>0 THEN jsonb_build_array(p.photos->0) ELSE '[]'::jsonb END END,'status','PUBLISHED','city_id',p.city_id,'updated_at',l.freshness_confirmed_at,'has_active_promotion',false)
 || CASE WHEN p_detail THEN jsonb_build_object('description',l.description,'amenities',p.amenities,'covered_surface_m2',p.covered_surface_m2,'parking_spaces',p.parking_spaces,'age_years',p.age_years,'floors_total',p.floors_total,'contact_name',CASE WHEN p.show_contact THEN p.contact_name ELSE NULL END,'contact_phone',CASE WHEN p.show_contact THEN p.contact_phone ELSE NULL END,'advertiser',kaza_private.public_advertiser(l,p)) ELSE '{}'::jsonb END
 FROM public.market_cycles c WHERE c.id=l.market_cycle_id;
$$;
