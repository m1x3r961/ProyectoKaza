import { IsOptional, IsUUID, IsNumber, IsPositive, IsInt, Min, Max } from 'class-validator';

/// DTO: Solicitud de pre-calificaciÃ³n de crÃ©dito hipotecario (Motor Banco UniÃ³n)
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
  termYears: number; // Plazo del crÃ©dito en aÃ±os (1 a 30)

  // Referencia opcional a la propiedad en Kaza
  @IsOptional() @IsUUID() listingId?: string;
}
