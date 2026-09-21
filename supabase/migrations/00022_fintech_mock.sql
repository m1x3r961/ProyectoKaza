-- ============================================================
-- 00022_fintech_mock.sql
-- Módulo Fintech Simulado (Mock Banco Unión) para Hackathon
-- Kaza x Incuba Union Tecnológico 3.0
-- ============================================================

-- ─── 1. WALLETS VIRTUALES ───────────────────────────────────
-- Cada usuario de Kaza tiene una billetera virtual con saldo ficticio
CREATE TABLE IF NOT EXISTS public.mock_wallets (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance        NUMERIC(14, 2) NOT NULL DEFAULT 5000.00, -- Saldo inicial de demo: 5,000 Bs
  currency       VARCHAR(3) NOT NULL DEFAULT 'BOB',
  is_active      BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ─── 2. TRANSACCIONES P2P ───────────────────────────────────
-- Registro inmutable de cada movimiento de dinero entre wallets
CREATE TABLE IF NOT EXISTS public.mock_wallet_transactions (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_wallet_id     UUID NOT NULL REFERENCES public.mock_wallets(id),
  receiver_wallet_id   UUID NOT NULL REFERENCES public.mock_wallets(id),
  amount               NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
  currency             VARCHAR(3) NOT NULL DEFAULT 'BOB',
  status               VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'
                         CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
  concept              TEXT,                -- Ej: "Reserva propiedad #uuid"
  reference_listing_id UUID,               -- Referencia opcional a un listing de Kaza
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 3. VALIDACIÓN KYC (Know Your Customer / Cumplimiento ASFI) ─
-- Simula el proceso de verificación de identidad que exige el banco
CREATE TABLE IF NOT EXISTS public.mock_user_kyc (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status            VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING', 'IN_REVIEW', 'VERIFIED', 'REJECTED')),
  kaza_score        INTEGER,               -- Score FinTech de 300-850 (estilo credit score)
  id_number         VARCHAR(20),           -- Número de carnet (no real, solo demo)
  rejection_reason  TEXT,
  reviewed_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ─── 4. SOLICITUDES DE CRÉDITO SIMULADAS ────────────────────
-- Registra cada solicitud de pre-calificación de crédito hipotecario
CREATE TABLE IF NOT EXISTS public.mock_credit_applications (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_id        UUID,                  -- Propiedad para la que solicita el crédito
  requested_amount  NUMERIC(14, 2) NOT NULL,
  term_years        INTEGER NOT NULL,
  monthly_income    NUMERIC(14, 2) NOT NULL,
  monthly_expenses  NUMERIC(14, 2) NOT NULL DEFAULT 0,
  applicant_age     INTEGER NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING', 'PRE_APPROVED', 'APPROVED', 'REJECTED')),
  -- Resultado del motor de scoring
  approved_amount   NUMERIC(14, 2),
  approved_rate     NUMERIC(5, 4),         -- Tasa anual ej: 0.0650 = 6.50%
  approved_term     INTEGER,
  monthly_fee       NUMERIC(14, 2),
  bank_product      VARCHAR(100),          -- Ej: "Crédito Vivienda Social Banco Unión"
  rejection_reason  TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 5. ÍNDICES DE RENDIMIENTO ──────────────────────────────
CREATE INDEX IF NOT EXISTS idx_mock_wallets_user_id
  ON public.mock_wallets(user_id);

CREATE INDEX IF NOT EXISTS idx_mock_transactions_sender
  ON public.mock_wallet_transactions(sender_wallet_id);

CREATE INDEX IF NOT EXISTS idx_mock_transactions_receiver
  ON public.mock_wallet_transactions(receiver_wallet_id);

CREATE INDEX IF NOT EXISTS idx_mock_kyc_user_id
  ON public.mock_user_kyc(user_id);

CREATE INDEX IF NOT EXISTS idx_mock_credit_user_id
  ON public.mock_credit_applications(user_id);

-- ─── 6. RLS (Row Level Security) ────────────────────────────
-- Los usuarios solo pueden ver sus propios datos financieros
ALTER TABLE public.mock_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_user_kyc ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_credit_applications ENABLE ROW LEVEL SECURITY;

-- Wallets: El usuario ve solo su wallet
CREATE POLICY "Users can view own wallet"
  ON public.mock_wallets FOR SELECT
  USING (auth.uid() = user_id);

-- Transacciones: El usuario ve las que envió o recibió
CREATE POLICY "Users can view own transactions"
  ON public.mock_wallet_transactions FOR SELECT
  USING (
    sender_wallet_id IN (SELECT id FROM public.mock_wallets WHERE user_id = auth.uid())
    OR
    receiver_wallet_id IN (SELECT id FROM public.mock_wallets WHERE user_id = auth.uid())
  );

-- KYC: El usuario ve solo su propio registro de identidad
CREATE POLICY "Users can view own kyc"
  ON public.mock_user_kyc FOR SELECT
  USING (auth.uid() = user_id);

-- Créditos: El usuario ve solo sus solicitudes
CREATE POLICY "Users can view own credit applications"
  ON public.mock_credit_applications FOR SELECT
  USING (auth.uid() = user_id);

-- Nota: Las escrituras se hacen SOLO desde el backend NestJS
-- usando el Service Role Key (que bypasea RLS), asegurando
-- que la lógica de negocio esté siempre protegida en el servidor.
