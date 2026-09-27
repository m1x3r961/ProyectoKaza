import { WorkflowsController } from './domain/workflows/workflows.controller';
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { SupabaseService } from './infrastructure/supabase/supabase.service';
import { ListingsController } from './domain/listings/listings.controller';
import { ListingsService } from './domain/listings/listings.service';
import { PromotionsController } from './domain/promotions/promotions.controller';
import { PromotionsService } from './domain/promotions/promotions.service';
import { FintechModule } from './domain/fintech/fintech.module';
import { AuthGuard } from './security/auth.guard';
import { RateGuard } from './security/rate.guard';
import { CatalogController } from './domain/catalog/catalog.controller';
import { AdminController } from './domain/admin/admin.controller';
import { AiController } from './domain/ai/ai.controller';
@Module({imports:[FintechModule],controllers:[WorkflowsController,AppController,ListingsController,PromotionsController,CatalogController,AdminController,AiController],providers:[SupabaseService,ListingsService,PromotionsService,{provide:APP_GUARD,useClass:RateGuard},{provide:APP_GUARD,useClass:AuthGuard}]})
export class AppModule {}
