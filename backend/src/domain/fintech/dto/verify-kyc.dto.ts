import { IsString, IsNotEmpty, IsOptional, Length } from 'class-validator';

/// DTO: Solicitud de verificación de identidad (KYC / ASFI)
export class VerifyKycDto {
  @IsString()
  @IsNotEmpty()
  @Length(6, 20)
  idNumber: string; // Número de carnet de identidad (ficticio en demo)

  @IsString()
  @IsNotEmpty()
  fullName: string; // Nombre completo del titular

  @IsOptional()
  @IsString()
  selfieBase64?: string; // Imagen de selfie en base64 (opcional en demo)
}
