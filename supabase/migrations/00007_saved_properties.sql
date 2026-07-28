CREATE TABLE IF NOT EXISTS public.saved_properties (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, property_id)
);

ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert for all users" ON public.saved_properties FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable select for all users" ON public.saved_properties FOR SELECT USING (true);
CREATE POLICY "Enable delete for all users" ON public.saved_properties FOR DELETE USING (true);
