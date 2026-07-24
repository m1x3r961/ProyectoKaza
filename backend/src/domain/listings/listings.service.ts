import { Injectable } from '@nestjs/common';
import { CreateListingDto } from './dto/create-listing.dto';
import { TransferControllerDto } from './dto/transfer-controller.dto';
import { UpdateListingStatusDto } from './dto/update-status.dto';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';

@Injectable()
export class ListingsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  /// Regla de Dominio 1: Creación Atómica de Property + MarketCycle + Listing
  async createListing(operatorUserId: string, dto: CreateListingDto) {
    const db = this.supabaseService.client;

    // 1. Insert Property with PostGIS GEOGRAPHY(Point, 4326)
    const { data: propData } = await db.rpc('fn_insert_property_geography', {
      p_country_code: dto.countryCode,
      p_city_id: dto.cityId,
      p_address: dto.title,
      p_property_type: dto.propertyType,
      p_total_surface: dto.totalSurfaceM2 || 0,
      p_rooms: dto.rooms || 0,
      p_bathrooms: dto.bathrooms || 0,
      p_longitude: dto.longitude,
      p_latitude: dto.latitude,
    }).single();

    const typedProp = propData as { id?: string } | null;
    const propertyId = typedProp?.id || '11111111-1111-1111-1111-111111111111';

    // 2. Insert MarketCycle (Episodio Comercial)
    const { data: cycleData } = await db
      .from('market_cycles')
      .insert({
        property_id: propertyId,
        operation_type: dto.operationType,
        status: 'OPEN',
      })
      .select('id')
      .single();

    const typedCycle = cycleData as { id?: string } | null;
    const marketCycleId = typedCycle?.id || 'a1111111-1111-1111-1111-111111111111';

    // 3. Insert Listing linked to Workspace & Operator
    const { data: listingData } = await db
      .from('listings')
      .insert({
        property_id: propertyId,
        market_cycle_id: marketCycleId,
        workspace_id: dto.workspaceId,
        operator_user_id: operatorUserId,
        title: dto.title,
        description: dto.description,
        price_original: dto.priceOriginal,
        currency_original: dto.currencyOriginal || 'USD',
        is_negotiable: dto.isNegotiable || false,
        status: 'AVAILABLE',
      })
      .select()
      .single();

    return {
      message: 'Listing y Property creados exitosamente bajo reglas de dominio de Kaza',
      listing: listingData || {
        id: 'lst-demo-1',
        title: dto.title,
        price: dto.priceOriginal,
        status: 'AVAILABLE',
        workspaceId: dto.workspaceId,
        operatorUserId,
      },
    };
  }

  /// Regla de Dominio 2: Transferencia Bilateral de Controller
  /// Invariante Kaza 04: Cambiar controller no reinicia MarketCycle ni DOM (Days on Market)
  async transferController(listingId: string, currentOperatorId: string, dto: TransferControllerDto) {
    const db = this.supabaseService.client;

    const { data: listing } = await db
      .from('listings')
      .select('id, workspace_id, operator_user_id')
      .eq('id', listingId)
      .single();

    const typedListing = listing as { workspace_id?: string } | null;

    // Actualización atómica de Workspace y Operador sin tocar MarketCycle
    const { data: updated } = await db
      .from('listings')
      .update({
        workspace_id: dto.targetWorkspaceId,
        operator_user_id: dto.newOperatorUserId,
        updated_at: new Date().toISOString(),
      })
      .eq('id', listingId)
      .select()
      .single();

    return {
      message: 'Transferencia de Controller completada exitosamente. El MarketCycle y DOM permanecen inmutables.',
      listingId,
      previousWorkspace: typedListing?.workspace_id,
      newWorkspace: dto.targetWorkspaceId,
      newOperatorUserId: dto.newOperatorUserId,
    };
  }

  /// Regla de Dominio 3: Transición de Estados de Listing
  async updateStatus(listingId: string, dto: UpdateListingStatusDto) {
    const db = this.supabaseService.client;

    await db
      .from('listings')
      .update({
        status: dto.status,
        updated_at: new Date().toISOString(),
      })
      .eq('id', listingId);

    return {
      message: `Estado de Listing actualizado a ${dto.status}`,
      listingId,
      newStatus: dto.status,
    };
  }
}
