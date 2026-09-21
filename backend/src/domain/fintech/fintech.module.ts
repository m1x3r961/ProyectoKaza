import { Module } from '@nestjs/common';
import { FintechController } from './fintech.controller';
import { FintechService } from './fintech.service';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';

/// Módulo FinTech Simulado (Mock Banco Unión)
/// Proporciona: KYC/ASFI, Scoring de Crédito y Wallet P2P
@Module({
  controllers: [FintechController],
  providers: [FintechService, SupabaseService],
  exports: [FintechService],
})
export class FintechModule {}
