import { IsString, IsNumber, IsEnum, IsBoolean, IsOptional, Min } from 'class-validator';

export class CreateListingDto {
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  workspaceId: string;

  @IsEnum(['SALE', 'RENT', 'ANTICRETICO'])
  operationType: string;

  @IsString()
  propertyType: string;

  @IsNumber()
  @Min(1)
  priceOriginal: number;

  @IsString()
  @IsOptional()
  currencyOriginal?: string = 'USD';

  @IsBoolean()
  @IsOptional()
  isNegotiable?: boolean = false;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsString()
  countryCode: string = 'BOL';

  @IsString()
  cityId: string = 'santa_cruz';

  @IsNumber()
  @IsOptional()
  totalSurfaceM2?: number;

  @IsNumber()
  @IsOptional()
  rooms?: number;

  @IsNumber()
  @IsOptional()
  bathrooms?: number;
}
