-- =============================================================================
-- KAZA - U05 / U06 (CRM AND SUBSCRIPTIONS)
-- Migration: 00014_crm_and_subscriptions.sql
-- =============================================================================

-- 1. ADD SUBSCRIPTION TIER TO PROFILES
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS subscription_tier VARCHAR(50) DEFAULT 'FREE'; 
-- Values: 'FREE', 'PLUS', 'PRO', 'BUSINESS'

-- 2. CRM CONTACTS TABLE (U06)
CREATE TABLE IF NOT EXISTS public.crm_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. CRM OPPORTUNITIES TABLE (U06 FUNNEL)
CREATE TABLE IF NOT EXISTS public.crm_opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES public.crm_contacts(id) ON DELETE SET NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    stage VARCHAR(50) NOT NULL DEFAULT 'PROSPECTO', -- 'PROSPECTO', 'VISITA', 'NEGOCIACION', 'CIERRE', 'PERDIDO'
    amount_expected NUMERIC(15,2) DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. CRM TASKS TABLE (U06 TASKS)
CREATE TABLE IF NOT EXISTS public.crm_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES public.crm_contacts(id) ON DELETE CASCADE,
    opportunity_id UUID REFERENCES public.crm_opportunities(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    due_date TIMESTAMPTZ,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- RLS POLICIES FOR CRM (Only the agent can see/manage their CRM data)
-- =============================================================================

ALTER TABLE public.crm_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_tasks ENABLE ROW LEVEL SECURITY;

-- CRM Contacts Policies
CREATE POLICY "Agent can select their own contacts" ON public.crm_contacts FOR SELECT USING (agent_id = auth.uid());
CREATE POLICY "Agent can insert their own contacts" ON public.crm_contacts FOR INSERT WITH CHECK (agent_id = auth.uid());
CREATE POLICY "Agent can update their own contacts" ON public.crm_contacts FOR UPDATE USING (agent_id = auth.uid());
CREATE POLICY "Agent can delete their own contacts" ON public.crm_contacts FOR DELETE USING (agent_id = auth.uid());

-- CRM Opportunities Policies
CREATE POLICY "Agent can select their own opportunities" ON public.crm_opportunities FOR SELECT USING (agent_id = auth.uid());
CREATE POLICY "Agent can insert their own opportunities" ON public.crm_opportunities FOR INSERT WITH CHECK (agent_id = auth.uid());
CREATE POLICY "Agent can update their own opportunities" ON public.crm_opportunities FOR UPDATE USING (agent_id = auth.uid());
CREATE POLICY "Agent can delete their own opportunities" ON public.crm_opportunities FOR DELETE USING (agent_id = auth.uid());

-- CRM Tasks Policies
CREATE POLICY "Agent can select their own tasks" ON public.crm_tasks FOR SELECT USING (agent_id = auth.uid());
CREATE POLICY "Agent can insert their own tasks" ON public.crm_tasks FOR INSERT WITH CHECK (agent_id = auth.uid());
CREATE POLICY "Agent can update their own tasks" ON public.crm_tasks FOR UPDATE USING (agent_id = auth.uid());
CREATE POLICY "Agent can delete their own tasks" ON public.crm_tasks FOR DELETE USING (agent_id = auth.uid());

-- =============================================================================
-- RPC TO UPDATE SUBSCRIPTION PLAN EASILY (FOR TESTING)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_upgrade_subscription(p_tier VARCHAR)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET subscription_tier = UPPER(p_tier)
    WHERE id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.fn_upgrade_subscription TO authenticated;
