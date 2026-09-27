import { IsString, IsNumber, IsIn, IsBoolean, IsOptional, Min, Max, IsUUID, MaxLength, IsInt, IsArray, ArrayMaxSize, IsUrl } from 'class-validator';
export class CreateListingDto {
 @IsString() @MaxLength(180) title: string;
 @IsString() @MaxLength(5000) @IsOptional() description?: string;
 @IsUUID() @IsOptional() workspaceId?: string;
 @IsIn(['SALE','RENT','ANTICRETICO']) operationType: string;
 @IsString() @MaxLength(80) propertyType: string;
 @IsNumber() @Min(0) @Max(1e12) priceOriginal: number;
 @IsIn(['USD','BOB']) currencyOriginal: string = 'USD';
 @IsBoolean() @IsOptional() isNegotiable?: boolean;
 @IsBoolean() @IsOptional() contactForPrice?: boolean;
 @IsNumber() @Min(-90) @Max(90) latitude: number;
 @IsNumber() @Min(-180) @Max(180) longitude: number;
 @IsString() @MaxLength(3) countryCode: string = 'BOL';
 @IsString() @MaxLength(50) cityId: string = 'santa_cruz';
 @IsString() @MaxLength(300) @IsOptional() address?: string;
 @IsNumber() @Min(0) @Max(1e8) @IsOptional() totalSurfaceM2?: number;
 @IsNumber() @Min(0) @Max(1e8) @IsOptional() coveredSurfaceM2?: number;
 @IsInt() @Min(0) @Max(1000) @IsOptional() rooms?: number;
 @IsInt() @Min(0) @Max(1000) @IsOptional() bathrooms?: number;
 @IsInt() @Min(0) @Max(1000) @IsOptional() parkingSpaces?: number;
 @IsInt() @Min(0) @Max(1000) @IsOptional() ageYears?: number;
 @IsInt() @Min(1) @Max(1000) @IsOptional() floorsTotal?: number;
 @IsArray() @ArrayMaxSize(20) @IsUrl({ protocols: ['https'], require_protocol: true }, { each: true }) @IsOptional() photos?: string[];
 @IsArray() @ArrayMaxSize(30) @IsString({ each: true }) @MaxLength(80,{each:true}) @IsOptional() amenities?: string[];
 @IsString() @MaxLength(120) @IsOptional() contactName?: string;
 @IsString() @MaxLength(40) @IsOptional() contactPhone?: string;
 @IsBoolean() @IsOptional() showContact?: boolean;
}
