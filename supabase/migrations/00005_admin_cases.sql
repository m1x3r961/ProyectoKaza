-- =============================================================================
-- KAZA ADMIN BACKOFFICE & MODERATION - ADMIN CASES & AUDIT TRAIL
-- Migration: 00005_admin_cases.sql
-- =============================================================================

-- Safe Enum Creation (Idempotent for PostgreSQL)
DO $$ BEGIN
    CREATE TYPE admin_case_status_enum AS ENUM (
        'NEW', 
        'TRIAGED', 
        'IN_REVIEW', 
        'WAITING_USER', 
        'RESOLVED', 
        'ESCALATED', 
        'DISMISSED', 
        'REOPENED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE admin_case_type_enum AS ENUM (
        'REPORT_LISTING', 
        'USER_VERIFICATION', 
        'ORGANIZATION_VERIFICATION', 
        'FRAUD_SUSPECT', 
        'DATA_CLAIM_DISPUTE', 
        'MEDIA_VERACITY_REPORT'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.admin_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_type admin_case_type_enum NOT NULL DEFAULT 'REPORT_LISTING',
    status admin_case_status_enum NOT NULL DEFAULT 'NEW',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    
    target_id UUID NOT NULL,
    reporter_user_id UUID REFERENCES auth.users(id),
    assigned_admin_user_id UUID REFERENCES auth.users(id),
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    audit_trail JSONB NOT NULL DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_cases ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SAMPLE SEED FOR ADMIN CASES (ON CONFLICT DO NOTHING)
-- -----------------------------------------------------------------------------
INSERT INTO public.admin_cases (id, case_type, status, priority, target_id, title, description)
VALUES 
(
    'c1111111-1111-1111-1111-111111111111',
    'USER_VERIFICATION',
    'NEW',
    'HIGH',
    '11111111-1111-1111-1111-111111111111',
    'Verificación de Identidad: Inmobiliaria Kaza Pro',
    'Solicitud de insignia Trust Badge con documento de registro de comercio.'
),
(
    'c2222222-2222-2222-2222-222222222222',
    'MEDIA_VERACITY_REPORT',
    'TRIAGED',
    'MEDIUM',
    '22222222-2222-2222-2222-222222222222',
    'Reporte de Veracidad: Foto marcada como REAL_PHOTO es Render',
    'El usuario reporta que la imagen principal del proyecto es una visualización 3D.'
),
(
    'c3333333-3333-3333-3333-333333333333',
    'REPORT_LISTING',
    'IN_REVIEW',
    'CRITICAL',
    '33333333-3333-3333-3333-333333333333',
    'Sospecha de Duplicado o Precio Fraudulento',
    'Revisión automática de discrepancia de precio frente al historial del MarketCycle.'
)
ON CONFLICT (id) DO NOTHING;
