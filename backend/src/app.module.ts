import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SupabaseService } from './infrastructure/supabase/supabase.service';
import { ListingsController } from './domain/listings/listings.controller';
import { ListingsService } from './domain/listings/listings.service';
import { PromotionsController } from './domain/promotions/promotions.controller';
import { PromotionsService } from './domain/promotions/promotions.service';
import { KazaIdentityAdapter } from './domain/identity/kaza-identity.adapter';
import { FintechModule } from './domain/fintech/fintech.module';

@Module({
  imports: [
    FintechModule, // 🏦 Módulo Simulado Banco Unión (Hackathon Incuba Union 3.0)
  ],
  controllers: [
    AppController, 
    ListingsController, 
    PromotionsController
  ],
  providers: [
    AppService, 
    SupabaseService, 
    ListingsService, 
    PromotionsService,
    KazaIdentityAdapter
  ],
})
export class AppModule {}
