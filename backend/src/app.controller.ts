import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { Public } from './security/access';
import { SupabaseService } from './infrastructure/supabase/supabase.service';
@Controller()
export class AppController {
 constructor(private readonly db: SupabaseService) {}
 @Public() @Get() health() { return { status: 'ok', service: 'kaza', mode: this.db.config.mode }; }
 @Public() @Get('health/ready') async ready() {
   const { error } = await this.db.client.from('kaza_admins').select('user_id').limit(1);
   if (error) throw new ServiceUnavailableException();
   return { status: 'ready' };
 }
}
