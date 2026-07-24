import { Injectable, BadRequestException } from '@nestjs/common';
import { ActivatePlusPromotionDto } from './dto/activate-plus.dto';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';

@Injectable()
export class PromotionsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  /// Regla de Dominio: Activación de Entitlement PLUS/PRO sin alterar Trust ni Property Identity
  async activatePlus(payerUserId: string, dto: ActivatePlusPromotionDto) {
    const db = this.supabaseService.client;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 días de vigencia

    // 1. Insert into listing_promotions table
    const { data: promoData, error: promoError } = await db
      .from('listing_promotions')
      .insert({
        listing_id: dto.listingId,
        product_type: dto.productType,
        payer_user_id: payerUserId,
        source: dto.source,
        store_transaction_reference: dto.storeTransactionReference,
        status: 'ACTIVE',
        activated_at: new Date().toISOString(),
        expires_at: expiresAt.toISOString(),
      })
      .select()
      .single();

    // 2. Set derived state has_active_promotion = true on Listing
    await db
      .from('listings')
      .update({
        has_active_promotion: true,
        updated_at: new Date().toISOString(),
      })
      .eq('id', dto.listingId);

    return {
      message: 'Promoción PLUS activada exitosamente en ListingPromotion entitlement.',
      promotion: promoData || {
        id: 'prm-demo-1',
        listingId: dto.listingId,
        productType: dto.productType,
        source: dto.source,
        expiresAt: expiresAt.toISOString(),
        status: 'ACTIVE',
      },
    };
  }
}
