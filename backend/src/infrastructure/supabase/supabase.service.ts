import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private supabaseClient: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL || 'https://mgzbfklvtxprqofiaivl.supabase.co';
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'SUPABASE_SERVICE_ROLE_KEY_PLACEHOLDER';
    
    this.supabaseClient = createClient(supabaseUrl, supabaseServiceKey);
  }

  get client(): SupabaseClient {
    return this.supabaseClient;
  }
}
