-- 00018_collaboration_system.sql
-- KAZA U13 SISTEMA DE COLABORACIÓN Y CO-CORRETAJE

-- ENUMS
CREATE TYPE collaboration_mode AS ENUM ('CO_BROKERAGE', 'PARTICIPATION', 'TEAM', 'PUNCTUAL');
CREATE TYPE collaboration_status AS ENUM ('DRAFT', 'INVITATION_SENT', 'ACTIVE', 'COMPLETED', 'CANCELLED');
CREATE TYPE member_role AS ENUM ('OWNER', 'ADMIN', 'AGENT', 'COLLABORATOR');
CREATE TYPE member_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

-- 1. COLLABORATIONS TABLE
CREATE TABLE public.collaborations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    mode collaboration_mode NOT NULL DEFAULT 'CO_BROKERAGE',
    status collaboration_status NOT NULL DEFAULT 'DRAFT',
    scope VARCHAR(255), -- e.g., 'Comercialización completa', 'Zona específica'
    requires_agreement BOOLEAN DEFAULT true,
    total_commission_value DECIMAL(12, 2), -- The total commission available to be split
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. COLLABORATION MEMBERS
CREATE TABLE public.collaboration_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collaboration_id UUID NOT NULL REFERENCES public.collaborations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role member_role NOT NULL DEFAULT 'COLLABORATOR',
    status member_status NOT NULL DEFAULT 'PENDING',
    commission_percentage DECIMAL(5, 2) DEFAULT 0.00, -- e.g., 50.00 for 50%
    joined_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collaboration_id, user_id)
);

-- 3. COLLABORATION MILESTONES (For tracking operation progress)
CREATE TABLE public.collaboration_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collaboration_id UUID NOT NULL REFERENCES public.collaborations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING', -- e.g., 'PENDING', 'IN_PROGRESS', 'COMPLETED'
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES
ALTER TABLE public.collaborations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaboration_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaboration_milestones ENABLE ROW LEVEL SECURITY;

-- Collaborations are viewable by participants and the property owner
CREATE POLICY "Users can view collaborations they are part of" ON public.collaborations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.collaboration_members cm 
            WHERE cm.collaboration_id = id AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view members of their collaborations" ON public.collaboration_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.collaboration_members cm 
            WHERE cm.collaboration_id = collaboration_id AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view milestones of their collaborations" ON public.collaboration_milestones
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.collaboration_members cm 
            WHERE cm.collaboration_id = collaboration_id AND cm.user_id = auth.uid()
        )
    );
