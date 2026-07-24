-- =============================================================================
-- KAZA MESSAGING & VISIT SAFETY PROTOCOL
-- Migration: 00004_messaging_and_visits.sql
-- =============================================================================

-- 1. Visit Status Enum
CREATE TYPE visit_status_enum AS ENUM (
    'REQUESTED', 
    'CONFIRMED', 
    'CHECKED_IN', 
    'COMPLETED', 
    'CANCELLED', 
    'DISPUTED'
);

-- 2. Visit Safety Records Table
CREATE TABLE IF NOT EXISTS public.visit_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    visitor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    host_workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    host_user_id UUID NOT NULL REFERENCES auth.users(id),
    
    scheduled_at TIMESTAMPTZ NOT NULL,
    status visit_status_enum NOT NULL DEFAULT 'REQUESTED',
    
    checked_in_at TIMESTAMPTZ,
    checked_out_at TIMESTAMPTZ,
    safety_contact_phone VARCHAR(50),
    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.visit_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus propias citas de visita"
ON public.visit_records FOR SELECT
USING (auth.uid() = visitor_user_id OR auth.uid() = host_user_id);

-- 3. Stored Procedure for Creating a Message with Conversation
CREATE OR REPLACE FUNCTION public.fn_send_kaza_message(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_content TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_message_id UUID;
BEGIN
    INSERT INTO public.messages (conversation_id, sender_user_id, content, metadata)
    VALUES (p_conversation_id, p_sender_id, p_content, p_metadata)
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$;
