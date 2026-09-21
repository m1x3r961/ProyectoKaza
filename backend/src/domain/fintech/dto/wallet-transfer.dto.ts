import { IsUUID, IsNumber, IsPositive, IsOptional, IsString } from 'class-validator';

/// DTO: Transferencia P2P entre wallets (pago de reserva)
export class WalletTransferDto {
  @IsUUID()
  receiverUserId: string; // UUID del usuario receptor (propietario/agencia)

  @IsNumber()
  @IsPositive()
  amount: number; // Monto a transferir en BOB

  @IsOptional()
  @IsString()
  concept?: string; // Ej: "Reserva propiedad Av. Arce #302"

  @IsOptional()
  @IsUUID()
  referenceListingId?: string; // UUID del listing al que corresponde la reserva
}
