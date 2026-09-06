-- ============================================================================
-- KAZA U08 — DESARROLLADORA: Migración de Base de Datos
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

-- 1. PERFILES PROFESIONALES (extiende profiles)
CREATE TABLE IF NOT EXISTS professional_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'AGENT' CHECK (role IN ('AGENT', 'DEVELOPER', 'INVESTOR', 'OWNER')),
  bio text,
  phone text,
  company_name text,
  specialty text,
  years_experience int DEFAULT 0,
  languages text[] DEFAULT ARRAY['ES']::text[],
  rating numeric(2,1) DEFAULT 0.0,
  total_reviews int DEFAULT 0,
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE professional_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all professional profiles" ON professional_profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own professional profile" ON professional_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own professional profile" ON professional_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. PROYECTOS DE DESARROLLADORA
CREATE TABLE IF NOT EXISTS dev_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id uuid REFERENCES organizations(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  project_type text NOT NULL DEFAULT 'RESIDENCIAL' CHECK (project_type IN ('RESIDENCIAL', 'COMERCIAL', 'MIXTO', 'INDUSTRIAL')),
  status text NOT NULL DEFAULT 'IDEA' CHECK (status IN ('IDEA', 'PLANIFICACION', 'LEGALIZACION', 'CONSTRUCCION', 'COMERCIALIZACION', 'ENTREGA', 'POST_VENTA')),
  total_units int DEFAULT 0,
  sold_units int DEFAULT 0,
  reserved_units int DEFAULT 0,
  available_units int DEFAULT 0,
  total_area_m2 numeric DEFAULT 0,
  estimated_investment numeric DEFAULT 0,
  start_date date,
  estimated_end_date date,
  progress_pct numeric(5,2) DEFAULT 0.00,
  city text,
  address text,
  latitude numeric,
  longitude numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE dev_projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own projects" ON dev_projects FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can insert own projects" ON dev_projects FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update own projects" ON dev_projects FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete own projects" ON dev_projects FOR DELETE USING (auth.uid() = owner_id);

-- 3. ETAPAS DEL PROYECTO
CREATE TABLE IF NOT EXISTS dev_project_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES dev_projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  stage_order int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'PENDIENTE' CHECK (status IN ('PENDIENTE', 'EN_PROGRESO', 'COMPLETADA')),
  progress_pct numeric(5,2) DEFAULT 0.00,
  start_date date,
  end_date date,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE dev_project_stages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own project stages" ON dev_project_stages FOR ALL
  USING (EXISTS (SELECT 1 FROM dev_projects WHERE dev_projects.id = dev_project_stages.project_id AND dev_projects.owner_id = auth.uid()));

-- 4. UNIDADES / TIPOLOGÍAS
CREATE TABLE IF NOT EXISTS dev_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES dev_projects(id) ON DELETE CASCADE,
  unit_code text NOT NULL,
  typology text NOT NULL DEFAULT 'DEPARTAMENTO' CHECK (typology IN ('DEPARTAMENTO', 'CASA', 'LOCAL', 'OFICINA', 'LOTE')),
  area_m2 numeric DEFAULT 0,
  bedrooms int DEFAULT 0,
  bathrooms int DEFAULT 0,
  floor_number int DEFAULT 1,
  price_usd numeric DEFAULT 0,
  status text NOT NULL DEFAULT 'DISPONIBLE' CHECK (status IN ('DISPONIBLE', 'RESERVADA', 'VENDIDA', 'ENTREGADA')),
  buyer_name text,
  buyer_contact text,
  sale_date date,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE dev_units ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own project units" ON dev_units FOR ALL
  USING (EXISTS (SELECT 1 FROM dev_projects WHERE dev_projects.id = dev_units.project_id AND dev_projects.owner_id = auth.uid()));

-- 5. DOCUMENTOS DEL PROYECTO
CREATE TABLE IF NOT EXISTS dev_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES dev_projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  doc_type text NOT NULL DEFAULT 'OTRO' CHECK (doc_type IN ('PLANO', 'PERMISO', 'CONTRATO', 'INFORME', 'OTRO')),
  file_url text,
  uploaded_at timestamptz DEFAULT now()
);

ALTER TABLE dev_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own project documents" ON dev_documents FOR ALL
  USING (EXISTS (SELECT 1 FROM dev_projects WHERE dev_projects.id = dev_documents.project_id AND dev_projects.owner_id = auth.uid()));

-- 6. REGISTROS FINANCIEROS
CREATE TABLE IF NOT EXISTS dev_financial_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES dev_projects(id) ON DELETE CASCADE,
  record_type text NOT NULL CHECK (record_type IN ('INGRESO', 'EGRESO')),
  category text NOT NULL DEFAULT 'OTRO' CHECK (category IN ('VENTA', 'CUOTA', 'MATERIAL', 'MANO_OBRA', 'PERMISO', 'MARKETING', 'OTRO')),
  amount numeric NOT NULL DEFAULT 0,
  description text,
  record_date date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE dev_financial_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own financial records" ON dev_financial_records FOR ALL
  USING (EXISTS (SELECT 1 FROM dev_projects WHERE dev_projects.id = dev_financial_records.project_id AND dev_projects.owner_id = auth.uid()));

-- ============================================================================
-- FUNCIÓN RPC para insertar perfil profesional de forma segura
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_upsert_professional_profile(
  p_role text DEFAULT 'AGENT',
  p_bio text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_company_name text DEFAULT NULL,
  p_specialty text DEFAULT NULL,
  p_years_experience int DEFAULT 0
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO professional_profiles (id, role, bio, phone, company_name, specialty, years_experience)
  VALUES (auth.uid(), p_role, p_bio, p_phone, p_company_name, p_specialty, p_years_experience)
  ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    bio = COALESCE(EXCLUDED.bio, professional_profiles.bio),
    phone = COALESCE(EXCLUDED.phone, professional_profiles.phone),
    company_name = COALESCE(EXCLUDED.company_name, professional_profiles.company_name),
    specialty = COALESCE(EXCLUDED.specialty, professional_profiles.specialty),
    years_experience = EXCLUDED.years_experience,
    updated_at = now();
END;
$$;
