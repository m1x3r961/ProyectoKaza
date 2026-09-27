import { Controller, Get, Post, Body, Param, ParseUUIDPipe } from '@nestjs/common';
import { IsString, IsUUID, Length, IsIn, IsEmail, IsOptional, IsBoolean, MaxLength } from 'class-validator';
import { Actor, CurrentActor } from '../../security/access';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
class MessageDto { @IsString() @Length(1,4000) content:string; @IsUUID() clientId:string; }
class OrgDto { @IsString() @Length(1,180) legal_name:string; @IsOptional() @IsString() @MaxLength(2000) description?:string; @IsOptional() @IsString() @MaxLength(300) website?:string; @IsOptional() @IsString() @MaxLength(500) logo_url?:string; @IsOptional() @IsString() @MaxLength(254) contact_email?:string; @IsOptional() @IsString() @MaxLength(40) contact_phone?:string; @IsOptional() @IsString() @MaxLength(100) city?:string; @IsOptional() @IsString() @MaxLength(300) address?:string; @IsIn(['DEVELOPER','AGENCY','PRO_AGENT']) org_type:string; }
class InviteDto { @IsEmail() email:string; @IsIn(['OPERATOR','VIEWER']) role:string; }
class RespondDto { @IsOptional() @IsString() @Length(32,32) code?:string; @IsOptional() @IsUUID() id?:string; @IsBoolean() accept:boolean; }
@Controller('api')
export class WorkflowsController {
 constructor(private readonly db:SupabaseService) {}
 @Get('conversations') conversations(@CurrentActor() a:Actor) { return this.db.rpc('kaza_conversations',{p_actor:a.id}); }
 @Get('saved') saved(@CurrentActor() a:Actor) { return this.db.rpc('kaza_saved',{p_actor:a.id}); }
 @Post('conversations/property/:id') start(@CurrentActor() a:Actor,@Param('id',ParseUUIDPipe) id:string) { return this.db.rpc('kaza_start_conversation',{p_actor:a.id,p_property:id}).then(id=>({id})); }
 @Post('conversations/:id/messages') send(@CurrentActor() a:Actor,@Param('id',ParseUUIDPipe) id:string,@Body() dto:MessageDto) { return this.db.rpc('kaza_send_message',{p_actor:a.id,p_conversation:id,p_content:dto.content,p_client:dto.clientId}); }
 @Post('organizations') org(@CurrentActor() a:Actor,@Body() dto:OrgDto) { return this.db.rpc('kaza_create_organization',{p_actor:a.id,p_data:dto}); }
 @Post('organizations/:id/invitations') invite(@CurrentActor() a:Actor,@Param('id',ParseUUIDPipe) id:string,@Body() dto:InviteDto) { return this.db.rpc('kaza_invite',{p_actor:a.id,p_org:id,p_email:dto.email,p_role:dto.role}); }
 @Post('invitations/respond') respond(@CurrentActor() a:Actor,@Body() dto:RespondDto) { return this.db.rpc('kaza_respond_invitation',{p_actor:a.id,p_code:dto.code||null,p_id:dto.id||null,p_accept:dto.accept}); }
}
