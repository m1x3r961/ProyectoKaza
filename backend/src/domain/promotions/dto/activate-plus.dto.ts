import { IsString, IsEnum, IsOptional } from 'class-validator';

export class ActivatePlusPromotionDto {
  @IsString()
  listingId: string;

  @IsString()
  productType: string = 'PLUS_MONTHLY'; // 'PLUS_MONTHLY', 'PLUS_BOOST'

  @IsEnum(['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE_WEB'])
  source: string;

  @IsString()
  storeTransactionReference: string;

  @IsString()
  @IsOptional()
  promotionContext?: string;
}
