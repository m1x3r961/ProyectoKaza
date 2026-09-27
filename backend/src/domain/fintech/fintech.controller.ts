import { CurrentActor, Actor, DemoOnly } from '../../security/access';
import {
  Controller,
  Post,
  Get,
  Body,
  Headers,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { FintechService } from './fintech.service';
import { VerifyKycDto } from './dto/verify-kyc.dto';
import { CreditScoreDto } from './dto/credit-score.dto';
import { WalletTransferDto } from './dto/wallet-transfer.dto';

/// ─── Módulo FinTech Simulado Banco Unión ──────────────────────────────────
/// Endpoints para el Hackathon Incuba Union Tecnológico 3.0
/// Todas las operaciones son simuladas (entorno de demostración)
///
/// Prefijo: /api/fintech
/// Autenticación: x-user-id header (en producción se usaría JWT)
/// ──────────────────────────────────────────────────────────────────────────

@Controller('api/fintech')
@DemoOnly()
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class FintechController {
  constructor(private readonly fintechService: FintechService) {}

  // ─── GET /api/fintech/profile ──────────────────────────────────────────
  // Dashboard financiero del usuario: wallet + KYC status + historial
  @Get('profile')
  async getProfile(
    @CurrentActor() actor: Actor,
  ) {
    return this.fintechService.getUserFintechProfile(actor.id);
  }

  // ─── GET /api/fintech/wallet ───────────────────────────────────────────
  // Obtiene o inicializa la wallet virtual del usuario (saldo inicial: 5,000 Bs)
  @Get('wallet')
  async getWallet(
    @CurrentActor() actor: Actor,
  ) {
    return this.fintechService.getOrCreateWallet(actor.id);
  }

  // ─── POST /api/fintech/kyc/verify ─────────────────────────────────────
  // Verifica la identidad del usuario contra el padrón (simulación ASFI)
  // Body: { idNumber, fullName, selfieBase64? }
  @Post('kyc/verify')
  async verifyKyc(
    @CurrentActor() actor: Actor,
    @Body() dto: VerifyKycDto,
  ) {
    return this.fintechService.verifyKyc(actor.id, dto);
  }

  // ─── POST /api/fintech/credit/score ───────────────────────────────────
  // Pre-califica al usuario para un crédito hipotecario Banco Unión
  // Body: { monthlyIncome, monthlyExpenses, applicantAge, requestedAmount, termYears, listingId? }
  @Post('credit/score')
  async creditScore(
    @CurrentActor() actor: Actor,
    @Body() dto: CreditScoreDto,
  ) {
    return this.fintechService.evaluateCreditScore(actor.id, dto);
  }

  // ─── POST /api/fintech/wallet/transfer ────────────────────────────────
  // Transfiere saldo P2P entre dos usuarios (pago de reserva de propiedad)
  // Body: { receiverUserId, amount, concept?, referenceListingId? }
  @Post('wallet/transfer')
  async walletTransfer(
    @CurrentActor() actor: Actor,
    @Body() dto: WalletTransferDto,
    @Headers("idempotency-key") key: string,
  ) {
    return this.fintechService.transferP2P(actor.id, dto, key);
  }
}
