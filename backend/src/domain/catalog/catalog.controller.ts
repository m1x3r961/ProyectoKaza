import { Controller, Get, Query, Param, ParseUUIDPipe } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsNumber, Min, Max, IsInt, IsOptional, IsIn, IsString, MaxLength } from 'class-validator';
import { Public } from '../../security/access';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
class Bounds {
 @Type(()=>Number) @IsNumber() @Min(-90) @Max(90) south = -90;
 @Type(()=>Number) @IsNumber() @Min(-90) @Max(90) north = 90;
 @Type(()=>Number) @IsNumber() @Min(-180) @Max(180) west = -180;
 @Type(()=>Number) @IsNumber() @Min(-180) @Max(180) east = 180;
 @Type(()=>Number) @IsInt() @Min(1) @Max(100) limit = 100;
 @Type(()=>Number) @IsInt() @Min(0) @Max(10000) offset = 0;
 @IsOptional() @IsIn(['SALE','RENT','ANTICRETICO']) operation?: string;
 @IsOptional() @IsString() @MaxLength(80) type?: string;
}
@Controller('api/catalog') @Public()
export class CatalogController {
 constructor(private readonly db: SupabaseService) {}
 @Get() list(@Query() q: Bounds) { return this.db.rpc('kaza_catalog',{p_query:q}); }
 @Get(':id') detail(@Param('id',ParseUUIDPipe) id: string) { return this.db.rpc('kaza_catalog',{p_query:{id,detail:true}}).then(rows=>rows[0] || null); }
}
