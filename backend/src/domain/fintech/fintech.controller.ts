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
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class FintechController {
  constructor(private readonly fintechService: FintechService) {}

  // ─── GET /api/fintech/profile ──────────────────────────────────────────
  // Dashboard financiero del usuario: wallet + KYC status + historial
  @Get('profile')
  async getProfile(
    @Headers('x-user-id') userId: string = 'usr-demo-fintech',
  ) {
    return this.fintechService.getUserFintechProfile(userId);
  }

  // ─── GET /api/fintech/wallet ───────────────────────────────────────────
  // Obtiene o inicializa la wallet virtual del usuario (saldo inicial: 5,000 Bs)
  @Get('wallet')
  async getWallet(
    @Headers('x-user-id') userId: string = 'usr-demo-fintech',
  ) {
    return this.fintechService.getOrCreateWallet(userId);
  }

  // ─── POST /api/fintech/kyc/verify ─────────────────────────────────────
  // Verifica la identidad del usuario contra el padrón (simulación ASFI)
  // Body: { idNumber, fullName, selfieBase64? }
  @Post('kyc/verify')
  async verifyKyc(
    @Headers('x-user-id') userId: string = 'usr-demo-fintech',
    @Body() dto: VerifyKycDto,
  ) {
    return this.fintechService.verifyKyc(userId, dto);
  }

  // ─── POST /api/fintech/credit/score ───────────────────────────────────
  // Pre-califica al usuario para un crédito hipotecario Banco Unión
  // Body: { monthlyIncome, monthlyExpenses, applicantAge, requestedAmount, termYears, listingId? }
  @Post('credit/score')
  async creditScore(
    @Headers('x-user-id') userId: string = 'usr-demo-fintech',
    @Body() dto: CreditScoreDto,
  ) {
    return this.fintechService.evaluateCreditScore(userId, dto);
  }

  // ─── POST /api/fintech/wallet/transfer ────────────────────────────────
  // Transfiere saldo P2P entre dos usuarios (pago de reserva de propiedad)
  // Body: { receiverUserId, amount, concept?, referenceListingId? }
  @Post('wallet/transfer')
  async walletTransfer(
    @Headers('x-user-id') userId: string = 'usr-demo-fintech',
    @Body() dto: WalletTransferDto,
  ) {
    return this.fintechService.transferP2P(userId, dto);
  }
}
