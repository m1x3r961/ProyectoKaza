import { Controller, Post, Patch, Get, Body, Param, Headers, ParseUUIDPipe } from '@nestjs/common';
import { ListingsService } from './listings.service';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
import { CurrentActor, Actor } from '../../security/access';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingStatusDto } from './dto/update-status.dto';
import { TransferControllerDto } from './dto/transfer-controller.dto';
@Controller('api/listings')
export class ListingsController {
 constructor(private readonly service: ListingsService, private readonly db: SupabaseService) {}
 @Get('mine') mine(@CurrentActor() a: Actor) { return this.db.rpc('kaza_my_listings', { p_actor: a.id }); }
 @Get('limits') limits(@CurrentActor() a: Actor) { return this.db.rpc('kaza_listing_limits', { p_actor: a.id }); }
 @Post() create(@CurrentActor() a: Actor, @Body() dto: CreateListingDto, @Headers('idempotency-key') key: string) { return this.service.createListing(a.id, dto, key); }
 @Patch(':id/status') status(@CurrentActor() a: Actor, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateListingStatusDto) { return this.service.command(a.id,id,'status',dto); }
 @Post(':id/refresh') refresh(@CurrentActor() a: Actor,@Param('id', ParseUUIDPipe) id: string) { return this.service.command(a.id,id,'refresh',{}); }
 @Post(':id/transfer-controller') transfer(@CurrentActor() a: Actor,@Param('id', ParseUUIDPipe) id: string,@Body() dto: TransferControllerDto) { return this.service.command(a.id,id,'transfer',dto); }
 @Post('transfers/:id/accept') accept(@CurrentActor() a: Actor,@Param('id', ParseUUIDPipe) id: string) { return this.db.rpc('kaza_accept_transfer',{p_actor:a.id,p_id:id}); }
}
