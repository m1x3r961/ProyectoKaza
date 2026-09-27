import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
import { VerifyKycDto } from './dto/verify-kyc.dto';
import { CreditScoreDto } from './dto/credit-score.dto';
import { WalletTransferDto } from './dto/wallet-transfer.dto';

// ─── Tipos exportados del módulo ───────────────────────────────────────────

export interface MockWallet {
  id: string;
  user_id: string;
  balance: number;
  currency: string;
  is_active: boolean;
}

interface MockKyc {
  id: string;
  user_id: string;
  status: string;
  kaza_score: number | null;
}

// ─── Constantes del Motor de Scoring Simulado (Banco Unión) ────────────────

const SCORE_MIN = 300;
const SCORE_MAX = 850;
const SALDO_INICIAL_DEMO = 5000; // Bs

// Productos crediticios del Banco Unión (simulados)
const BANK_PRODUCTS = [
  {
    name: 'Crédito Vivienda Social Banco Unión',
    rate: 0.055,      // 5.5% anual
    maxTerm: 25,
    minScore: 620,
    maxAmount: 300000,
  },
  {
    name: 'Crédito Vivienda Progresiva',
    rate: 0.065,      // 6.5% anual
    maxTerm: 20,
    minScore: 550,
    maxAmount: 500000,
  },
  {
    name: 'Crédito Inmobiliario Premium',
    rate: 0.075,      // 7.5% anual
    maxTerm: 30,
    minScore: 700,
    maxAmount: 1500000,
  },
];

// ─── Servicio Principal ─────────────────────────────────────────────────────

@Injectable()
export class FintechService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private get db() {
    return this.supabaseService.client;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. OBTENER O CREAR WALLET DEL USUARIO
  // ───────────────────────────────────────────────────────────────────────────

  async getOrCreateWallet(userId: string): Promise<MockWallet> {
    const { data: existing } = await this.db
      .from('mock_wallets')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle().throwOnError();

    if (existing) return existing as MockWallet;

    // Si no tiene wallet, se crea con saldo de demo
    const { data: created, error } = await this.db
      .from('mock_wallets')
      .insert({ user_id: userId, balance: SALDO_INICIAL_DEMO })
      .select()
      .maybeSingle().throwOnError();

    if (error) throw new BadRequestException('No se pudo crear la wallet del usuario.');
    return created as MockWallet;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. KYC: VERIFICACIÓN DE IDENTIDAD (Simulación ASFI)
  // ───────────────────────────────────────────────────────────────────────────

  async verifyKyc(userId: string, dto: VerifyKycDto) {
    // Verificar si ya está procesado
    const { data: existing } = await this.db
      .from('mock_user_kyc')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle().throwOnError();

    const existingKyc = existing as MockKyc | null;

    if (existingKyc?.status === 'VERIFIED') {
      return {
        success: true,
        status: 'VERIFIED',
        message: 'Tu verificación simulada ya está registrada.',
        kazaScore: existingKyc.kaza_score,
        alreadyVerified: true,
      };
    }

    // ── Motor de Validación Simulado ──
    // En demo: DNIs que terminen en número impar se aprueban; par se rechazan (para demo)
    const lastDigit = parseInt(dto.idNumber.slice(-1), 10);
    const isApproved = !isNaN(lastDigit) ? lastDigit % 2 !== 0 : true;

    // Simular delay de procesamiento (banco revisando)
    const kazaScore = isApproved
      ? Math.floor(Math.random() * (SCORE_MAX - 620) + 620)
      : Math.floor(Math.random() * (550 - SCORE_MIN) + SCORE_MIN);

    const newStatus = isApproved ? 'VERIFIED' : 'REJECTED';
    const rejectionReason = isApproved
      ? null
      : 'Los datos proporcionados no coinciden con los registros del Padrón Nacional (simulación).';

    // Guardar o actualizar en BD
    if (existingKyc) {
      await this.db
        .from('mock_user_kyc')
        .update({
          status: newStatus,
          kaza_score: kazaScore,
          id_number: dto.idNumber,
          rejection_reason: rejectionReason,
          reviewed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('user_id', userId).throwOnError();
    } else {
      await this.db.from('mock_user_kyc').insert({
        user_id: userId,
        status: newStatus,
        kaza_score: kazaScore,
        id_number: dto.idNumber,
        rejection_reason: rejectionReason,
        reviewed_at: new Date().toISOString(),
      }).throwOnError();
    }

    return {
      success: isApproved,
      status: newStatus,
      message: isApproved
        ? 'Verificación simulada aprobada. No acredita identidad ni cumplimiento bancario.'
        : '❌ Verificación rechazada. Revisa tus datos e inténtalo nuevamente.',
      kazaScore: isApproved ? kazaScore : null,
      rejectionReason,
      // Metadatos del motor de evaluación para el pitch
      evaluatedBy: 'Motor KYC Banco Unión (Simulado)',
      simulation: true,
      processedAt: new Date().toISOString(),
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. SCORING DE CRÉDITO: PRE-CALIFICACIÓN HIPOTECARIA
  // ───────────────────────────────────────────────────────────────────────────

  async evaluateCreditScore(userId: string, dto: CreditScoreDto) {
    // Verificar KYC primero
    const { data: kyc } = await this.db
      .from('mock_user_kyc')
      .select('status, kaza_score')
      .eq('user_id', userId)
      .maybeSingle().throwOnError();

    const typedKyc = kyc as MockKyc | null;

    if (!typedKyc || typedKyc.status !== 'VERIFIED') {
      throw new BadRequestException(
        'Debes verificar tu identidad (KYC) antes de solicitar un crédito.',
      );
    }

    const kazaScore = typedKyc.kaza_score ?? SCORE_MIN;

    // ── Motor de Scoring Financiero Simulado ──
    const netIncome = dto.monthlyIncome - dto.monthlyExpenses;
    if (netIncome <= 0) throw new BadRequestException("El ingreso neto debe ser positivo.");
    const debtToIncomeRatio = dto.requestedAmount / (netIncome * 12 * dto.termYears);
    const ageRiskFactor = dto.applicantAge > 55 ? 0.8 : 1.0;

    // Capacidad de pago máxima: 30% del ingreso neto mensual (regla bancaria boliviana)
    const maxMonthlyPayment = netIncome * 0.30;

    // Buscar el mejor producto del banco para este perfil
    const eligibleProducts = BANK_PRODUCTS.filter(
      (p) =>
        kazaScore >= p.minScore &&
        dto.requestedAmount <= p.maxAmount &&
        dto.termYears <= p.maxTerm,
    );

    if (eligibleProducts.length === 0 || kazaScore < 500 || debtToIncomeRatio > 1.5 * ageRiskFactor) {
      // Guardar solicitud rechazada
      await this.db.from('mock_credit_applications').insert({
        user_id: userId,
        listing_id: dto.listingId || null,
        requested_amount: dto.requestedAmount,
        term_years: dto.termYears,
        monthly_income: dto.monthlyIncome,
        monthly_expenses: dto.monthlyExpenses,
        applicant_age: dto.applicantAge,
        status: 'REJECTED',
        rejection_reason: 'Perfil de riesgo no cumple los requisitos mínimos del producto solicitado.',
      }).throwOnError();

      return {
        success: false,
        status: 'REJECTED',
        message: '❌ Pre-calificación no aprobada.',
        kazaScore,
        rejectionReason: 'Tu perfil financiero actual no cumple los requisitos mínimos. Considera reducir el monto o ampliar el plazo.',
        recommendations: [
          'Incrementar ingresos demostrables o reducir gastos fijos.',
          `Tu Kaza Score actual es ${kazaScore}. Necesitas al menos 550 para calificar.`,
          'Considera un co-deudor para mejorar tu calificación.',
        ],
        evaluatedBy: 'Motor de Riesgo Banco Unión (Simulado)',
        processedAt: new Date().toISOString(),
      };
    }

    // Seleccionar el mejor producto (menor tasa entre los elegibles)
    const bestProduct = eligibleProducts.sort((a, b) => a.rate - b.rate)[0];

    // Cálculo de cuota mensual con fórmula de amortización francesa
    const monthlyRate = bestProduct.rate / 12;
    const totalMonths = dto.termYears * 12;
    const monthlyFee =
      (dto.requestedAmount * monthlyRate * Math.pow(1 + monthlyRate, totalMonths)) /
      (Math.pow(1 + monthlyRate, totalMonths) - 1);

    const isAffordable = monthlyFee <= maxMonthlyPayment;
    const finalStatus = isAffordable ? 'PRE_APPROVED' : 'REJECTED';

    // Guardar solicitud en BD
    await this.db.from('mock_credit_applications').insert({
      user_id: userId,
      listing_id: dto.listingId || null,
      requested_amount: dto.requestedAmount,
      term_years: dto.termYears,
      monthly_income: dto.monthlyIncome,
      monthly_expenses: dto.monthlyExpenses,
      applicant_age: dto.applicantAge,
      status: finalStatus,
      approved_amount: isAffordable ? dto.requestedAmount : null,
      approved_rate: isAffordable ? bestProduct.rate : null,
      approved_term: isAffordable ? dto.termYears : null,
      monthly_fee: isAffordable ? monthlyFee : null,
      bank_product: isAffordable ? bestProduct.name : null,
      rejection_reason: isAffordable
        ? null
        : `La cuota mensual estimada (${monthlyFee.toFixed(2)} Bs) supera el 30% de tu ingreso neto.`,
    }).throwOnError();

    if (!isAffordable) {
      return {
        success: false,
        status: 'REJECTED',
        message: '❌ La cuota mensual supera tu capacidad de pago.',
        kazaScore,
        monthlyFee: Math.round(monthlyFee),
        maxMonthlyPayment: Math.round(maxMonthlyPayment),
        rejectionReason: `La cuota estimada es ${Math.round(monthlyFee)} Bs/mes pero tu capacidad máxima es ${Math.round(maxMonthlyPayment)} Bs/mes.`,
        recommendations: [
          `Considera ampliar el plazo a ${Math.min(dto.termYears + 5, 30)} años.`,
          `Reduce el monto solicitado a ${Math.round(maxMonthlyPayment * totalMonths * 0.8).toLocaleString()} Bs aproximadamente.`,
        ],
        evaluatedBy: 'Motor de Riesgo Banco Unión (Simulado)',
        processedAt: new Date().toISOString(),
      };
    }

    return {
      success: true,
      status: 'PRE_APPROVED',
      message: 'Simulación aprobada. No constituye una oferta ni preaprobación bancaria.',
      kazaScore,
      bankProduct: bestProduct.name,
      approvedAmount: dto.requestedAmount,
      currency: 'BOB',
      annualRate: `${(bestProduct.rate * 100).toFixed(2)}%`,
      termYears: dto.termYears,
      monthlyFee: Math.round(monthlyFee),
      totalToPayback: Math.round(monthlyFee * totalMonths),
      maxCapacity: Math.round(maxMonthlyPayment),
      nextStep: 'Resultado exclusivo de demostración; no es un comprobante bancario.',
      evaluatedBy: 'Motor de Riesgo Banco Unión (Simulado)',
      simulation: true,
      processedAt: new Date().toISOString(),
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. TRANSFERENCIA P2P: PAGO DE RESERVA
  // ───────────────────────────────────────────────────────────────────────────

  async transferP2P(senderUserId: string, dto: WalletTransferDto, key: string) {
    if (!key || !/^[a-zA-Z0-9_-]{16,100}$/.test(key)) throw new BadRequestException('Idempotency-Key requerido.');
    return this.supabaseService.rpc('kaza_mock_transfer', { p_actor: senderUserId, p_receiver: dto.receiverUserId, p_amount: dto.amount, p_key: key, p_concept: dto.concept || 'Reserva simulada', p_listing: dto.referenceListingId || null });
  }

  async getUserFintechProfile(userId: string) {
    const wallet = await this.getOrCreateWallet(userId);

    const { data: kyc } = await this.db
      .from('mock_user_kyc')
      .select('status, kaza_score')
      .eq('user_id', userId)
      .maybeSingle().throwOnError();

    const { data: transactions } = await this.db
      .from('mock_wallet_transactions')
      .select('*')
      .or(`sender_wallet_id.eq.${wallet.id},receiver_wallet_id.eq.${wallet.id}`)
      .order('created_at', { ascending: false })
      .limit(10).throwOnError();

    const { data: creditApps } = await this.db
      .from('mock_credit_applications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5).throwOnError();

    const typedKyc = kyc as MockKyc | null;

    return {
      wallet: {
        id: wallet.id,
        userId: wallet.user_id,
        balance: wallet.balance,
        currency: wallet.currency,
        isActive: wallet.is_active,
      },
      identity: {
        kycStatus: typedKyc?.status || 'NOT_STARTED',
        kazaScore: typedKyc?.kaza_score || null,
        scoreLabel: this.getScoreLabel(typedKyc?.kaza_score),
      },
      recentTransactions: transactions || [],
      creditApplications: creditApps || [],
    };
  }

  // ── Helper: Etiqueta del Score ──
  private getScoreLabel(score: number | null | undefined): string {
    if (!score) return 'Sin evaluar';
    if (score >= 750) return 'Excelente';
    if (score >= 700) return 'Muy bueno';
    if (score >= 650) return 'Bueno';
    if (score >= 600) return 'Regular';
    if (score >= 550) return 'Bajo';
    return 'Muy bajo';
  }
}
