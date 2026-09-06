-- ============================================================================
-- KAZA U08 — DATOS DE EJEMPLO (SEED)
-- Ejecutar DESPUÉS de la migración u08_desarrolladora.sql
-- ============================================================================

-- Nota: Estos datos seed usan funciones de inserción directa.
-- El owner_id se llenará dinámicamente al crear la sesión del usuario.
-- Para la demo, usamos una función que inserta datos de prueba para el usuario actual.

CREATE OR REPLACE FUNCTION fn_seed_developer_demo()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_proj1_id uuid;
  v_proj2_id uuid;
BEGIN
  -- Verificar que el usuario existe
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No hay sesión activa';
  END IF;

  -- Crear perfil profesional de Desarrollador
  INSERT INTO professional_profiles (id, role, bio, phone, company_name, specialty, years_experience, languages, rating, total_reviews, is_verified)
  VALUES (
    v_user_id,
    'DEVELOPER',
    'Desarrolladora inmobiliaria con más de 8 años de experiencia en proyectos residenciales y comerciales en Santa Cruz, Bolivia.',
    '+591 700 12345',
    'KAZA Desarrollos S.R.L.',
    'Residencial Premium',
    8,
    ARRAY['ES', 'EN'],
    4.8,
    128,
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'DEVELOPER',
    bio = EXCLUDED.bio,
    company_name = EXCLUDED.company_name,
    specialty = EXCLUDED.specialty,
    rating = EXCLUDED.rating,
    total_reviews = EXCLUDED.total_reviews,
    is_verified = true;

  -- ════════════════════════════════════════════════════════════════
  -- PROYECTO 1: Torres del Valle (En Construcción)
  -- ════════════════════════════════════════════════════════════════
  v_proj1_id := gen_random_uuid();
  INSERT INTO dev_projects (id, owner_id, name, description, project_type, status, total_units, sold_units, reserved_units, available_units, total_area_m2, estimated_investment, start_date, estimated_end_date, progress_pct, city, address)
  VALUES (
    v_proj1_id, v_user_id,
    'Torres del Valle',
    'Complejo residencial de 2 torres con 40 departamentos, amenities premium incluyendo piscina, gimnasio y salón de eventos.',
    'RESIDENCIAL', 'CONSTRUCCION',
    40, 18, 7, 15,
    12500.00, 2500000.00,
    '2025-03-01', '2026-12-15',
    62.5,
    'Santa Cruz', 'Av. San Martín esq. 3er Anillo'
  );

  -- Etapas del Proyecto 1
  INSERT INTO dev_project_stages (project_id, name, stage_order, status, progress_pct, start_date, end_date) VALUES
    (v_proj1_id, 'Diseño arquitectónico', 1, 'COMPLETADA', 100.00, '2025-01-15', '2025-03-01'),
    (v_proj1_id, 'Permisos y legalización', 2, 'COMPLETADA', 100.00, '2025-03-01', '2025-05-15'),
    (v_proj1_id, 'Cimentación y estructura', 3, 'COMPLETADA', 100.00, '2025-05-20', '2025-09-30'),
    (v_proj1_id, 'Obra gris Torre A', 4, 'EN_PROGRESO', 85.00, '2025-10-01', NULL),
    (v_proj1_id, 'Obra gris Torre B', 5, 'EN_PROGRESO', 45.00, '2025-11-15', NULL),
    (v_proj1_id, 'Acabados interiores', 6, 'PENDIENTE', 0.00, NULL, NULL),
    (v_proj1_id, 'Áreas comunes y amenities', 7, 'PENDIENTE', 0.00, NULL, NULL);

  -- Unidades del Proyecto 1 (muestra representativa)
  INSERT INTO dev_units (project_id, unit_code, typology, area_m2, bedrooms, bathrooms, floor_number, price_usd, status, buyer_name, sale_date) VALUES
    (v_proj1_id, 'A-101', 'DEPARTAMENTO', 85.0, 2, 2, 1, 78000, 'VENDIDA', 'Carlos Mendoza', '2025-06-15'),
    (v_proj1_id, 'A-102', 'DEPARTAMENTO', 65.0, 1, 1, 1, 58000, 'VENDIDA', 'María López', '2025-07-01'),
    (v_proj1_id, 'A-201', 'DEPARTAMENTO', 120.0, 3, 2, 2, 115000, 'RESERVADA', NULL, NULL),
    (v_proj1_id, 'A-202', 'DEPARTAMENTO', 85.0, 2, 2, 2, 82000, 'VENDIDA', 'Juan Pérez', '2025-08-20'),
    (v_proj1_id, 'A-301', 'DEPARTAMENTO', 120.0, 3, 2, 3, 120000, 'DISPONIBLE', NULL, NULL),
    (v_proj1_id, 'A-302', 'DEPARTAMENTO', 65.0, 1, 1, 3, 62000, 'RESERVADA', NULL, NULL),
    (v_proj1_id, 'B-101', 'DEPARTAMENTO', 95.0, 2, 2, 1, 85000, 'VENDIDA', 'Ana Gutiérrez', '2025-09-10'),
    (v_proj1_id, 'B-102', 'DEPARTAMENTO', 75.0, 2, 1, 1, 68000, 'DISPONIBLE', NULL, NULL),
    (v_proj1_id, 'B-201', 'DEPARTAMENTO', 150.0, 3, 3, 2, 145000, 'VENDIDA', 'Roberto Flores', '2025-10-01'),
    (v_proj1_id, 'B-301', 'DEPARTAMENTO', 150.0, 3, 3, 3, 155000, 'DISPONIBLE', NULL, NULL),
    (v_proj1_id, 'PH-A', 'DEPARTAMENTO', 200.0, 4, 3, 10, 250000, 'RESERVADA', NULL, NULL),
    (v_proj1_id, 'PH-B', 'DEPARTAMENTO', 220.0, 4, 4, 10, 280000, 'DISPONIBLE', NULL, NULL);

  -- Documentos del Proyecto 1
  INSERT INTO dev_documents (project_id, name, doc_type) VALUES
    (v_proj1_id, 'Plano arquitectónico general', 'PLANO'),
    (v_proj1_id, 'Permiso de construcción municipal', 'PERMISO'),
    (v_proj1_id, 'Estudio de suelos', 'INFORME'),
    (v_proj1_id, 'Memoria de cálculo estructural', 'INFORME'),
    (v_proj1_id, 'Contrato con constructora principal', 'CONTRATO');

  -- Registros financieros del Proyecto 1
  INSERT INTO dev_financial_records (project_id, record_type, category, amount, description, record_date) VALUES
    (v_proj1_id, 'INGRESO', 'VENTA', 78000, 'Venta A-101 - Carlos Mendoza', '2025-06-15'),
    (v_proj1_id, 'INGRESO', 'VENTA', 58000, 'Venta A-102 - María López', '2025-07-01'),
    (v_proj1_id, 'INGRESO', 'VENTA', 82000, 'Venta A-202 - Juan Pérez', '2025-08-20'),
    (v_proj1_id, 'INGRESO', 'VENTA', 85000, 'Venta B-101 - Ana Gutiérrez', '2025-09-10'),
    (v_proj1_id, 'INGRESO', 'VENTA', 145000, 'Venta B-201 - Roberto Flores', '2025-10-01'),
    (v_proj1_id, 'INGRESO', 'CUOTA', 35000, 'Anticipo reserva A-201', '2025-08-01'),
    (v_proj1_id, 'INGRESO', 'CUOTA', 18000, 'Anticipo reserva A-302', '2025-09-15'),
    (v_proj1_id, 'INGRESO', 'CUOTA', 75000, 'Anticipo reserva PH-A', '2025-10-20'),
    (v_proj1_id, 'EGRESO', 'MATERIAL', 320000, 'Hormigón y acero - Fase cimentación', '2025-05-25'),
    (v_proj1_id, 'EGRESO', 'MANO_OBRA', 185000, 'Cuadrilla estructura Q2-Q3 2025', '2025-09-30'),
    (v_proj1_id, 'EGRESO', 'MATERIAL', 210000, 'Materiales obra gris Torres A y B', '2025-11-01'),
    (v_proj1_id, 'EGRESO', 'PERMISO', 15000, 'Tasas municipales y permisos', '2025-03-10'),
    (v_proj1_id, 'EGRESO', 'MARKETING', 28000, 'Campaña lanzamiento digital + stands', '2025-06-01');

  -- ════════════════════════════════════════════════════════════════
  -- PROYECTO 2: Plaza Comercial Norte (En Planificación)
  -- ════════════════════════════════════════════════════════════════
  v_proj2_id := gen_random_uuid();
  INSERT INTO dev_projects (id, owner_id, name, description, project_type, status, total_units, sold_units, reserved_units, available_units, total_area_m2, estimated_investment, start_date, estimated_end_date, progress_pct, city, address)
  VALUES (
    v_proj2_id, v_user_id,
    'Plaza Comercial Norte',
    'Centro comercial de 3 niveles con 24 locales comerciales, food court y estacionamiento subterráneo.',
    'COMERCIAL', 'PLANIFICACION',
    24, 0, 3, 21,
    8500.00, 1800000.00,
    '2026-01-15', '2027-06-30',
    5.0,
    'Santa Cruz', 'Km 8 al Norte, Carretera a Warnes'
  );

  -- Etapas del Proyecto 2
  INSERT INTO dev_project_stages (project_id, name, stage_order, status, progress_pct) VALUES
    (v_proj2_id, 'Estudio de mercado', 1, 'COMPLETADA', 100.00),
    (v_proj2_id, 'Diseño arquitectónico', 2, 'EN_PROGRESO', 40.00),
    (v_proj2_id, 'Trámites y permisos', 3, 'PENDIENTE', 0.00),
    (v_proj2_id, 'Construcción', 4, 'PENDIENTE', 0.00),
    (v_proj2_id, 'Comercialización', 5, 'PENDIENTE', 0.00);

  -- Unidades del Proyecto 2
  INSERT INTO dev_units (project_id, unit_code, typology, area_m2, floor_number, price_usd, status) VALUES
    (v_proj2_id, 'L-001', 'LOCAL', 120.0, 1, 95000, 'RESERVADA'),
    (v_proj2_id, 'L-002', 'LOCAL', 85.0, 1, 72000, 'DISPONIBLE'),
    (v_proj2_id, 'L-003', 'LOCAL', 200.0, 1, 165000, 'RESERVADA'),
    (v_proj2_id, 'L-004', 'LOCAL', 60.0, 1, 48000, 'DISPONIBLE'),
    (v_proj2_id, 'L-101', 'LOCAL', 95.0, 2, 78000, 'DISPONIBLE'),
    (v_proj2_id, 'L-102', 'LOCAL', 110.0, 2, 88000, 'RESERVADA'),
    (v_proj2_id, 'L-201', 'LOCAL', 150.0, 3, 110000, 'DISPONIBLE'),
    (v_proj2_id, 'L-202', 'LOCAL', 75.0, 3, 58000, 'DISPONIBLE');

  -- Registros financieros del Proyecto 2
  INSERT INTO dev_financial_records (project_id, record_type, category, amount, description, record_date) VALUES
    (v_proj2_id, 'INGRESO', 'CUOTA', 28500, 'Anticipo reserva L-001', '2025-11-15'),
    (v_proj2_id, 'INGRESO', 'CUOTA', 49500, 'Anticipo reserva L-003', '2025-12-01'),
    (v_proj2_id, 'EGRESO', 'OTRO', 25000, 'Estudio de factibilidad y mercado', '2025-10-01'),
    (v_proj2_id, 'EGRESO', 'OTRO', 45000, 'Diseño arquitectónico (avance 40%)', '2026-01-20');

END;
$$;
