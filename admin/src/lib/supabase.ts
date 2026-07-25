import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://mgzbfklvtxprqofiaivl.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_Hx6ofANMtz9ZIq8exX16xw_s0sVUHzc';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
