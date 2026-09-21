import { IsNumber, IsPositive, IsInt, Min, Max } from 'class-validator';

/// DTO: Solicitud de pre-calificación de crédito hipotecario (Motor Banco Unión)
export class CreditScoreDto {
  @IsNumber()
  @IsPositive()
  monthlyIncome: number; // Ingresos mensuales en BOB

  @IsNumber()
  @Min(0)
  monthlyExpenses: number; // Gastos mensuales fijos en BOB

  @IsInt()
  @Min(18)
  @Max(70)
  applicantAge: number; // Edad del solicitante

  @IsNumber()
  @IsPositive()
  requestedAmount: number; // Monto de la propiedad que desea comprar en BOB

  @IsInt()
  @Min(1)
  @Max(30)
  termYears: number; // Plazo del crédito en años (1 a 30)

  // Referencia opcional a la propiedad en Kaza
  listingId?: string;
}
