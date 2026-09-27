import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
import { CreateListingDto } from './dto/create-listing.dto';
@Injectable()
export class ListingsService {
 constructor(private readonly db: SupabaseService) {}
 createListing(actor: string, dto: CreateListingDto, key: string) {
   if (!key || !/^[a-zA-Z0-9_-]{16,100}$/.test(key)) throw new BadRequestException('Idempotency-Key requerido.');
   if (!dto.title.trim() || (!dto.contactForPrice && dto.priceOriginal <= 0)) throw new BadRequestException('Revisa título y precio.');
   const prefix = `${this.db.config.url}/storage/v1/object/public/property-photos/${actor}/`;
   if (dto.photos?.some(url => !url.startsWith(prefix) || /%2e|%2f|\.\./i.test(url))) throw new BadRequestException('Las fotos deben pertenecer al usuario.');
   return this.db.rpc('kaza_publish', { p_actor: actor, p_key: key, p_data: dto });
 }
 command(actor: string, id: string, action: string, data: object) { return this.db.rpc('kaza_listing_command', { p_actor: actor, p_id: id, p_action: action, p_data: data }); }
}
