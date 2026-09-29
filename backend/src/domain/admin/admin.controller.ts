import { Controller, Get, Post, Body, Param, ParseUUIDPipe } from '@nestjs/common';
import { IsIn, IsString, Length } from 'class-validator';
import { Admin, AdminBootstrap, Actor, CurrentActor } from '../../security/access';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
class ModerateDto {
 @IsIn(['suspend_user','restore_user','delete_user','suspend_listing','restore_listing','resolve_case']) action: string;
 @IsString() @Length(8,500) reason: string;
}
@Controller('api/admin') @Admin()
export class AdminController {
 @Post('access') @AdminBootstrap() access() { return { authorized: true }; }
 constructor(private readonly db: SupabaseService) {}
 @Get('dashboard') dashboard(@CurrentActor() a: Actor) { return this.db.rpc('kaza_admin_dashboard',{p_actor:a.id}); }
 @Post(':id/moderate') moderate(@CurrentActor() a: Actor,@Param('id',ParseUUIDPipe) id:string,@Body() dto:ModerateDto) { return this.db.rpc('kaza_moderate',{p_actor:a.id,p_id:id,p_action:dto.action,p_reason:dto.reason}); }
}
