import { IsIn, IsInt, Min } from 'class-validator';
export class UpdateListingStatusDto {
 @IsIn(['AVAILABLE','RESERVED','CLOSED','PAUSED','WITHDRAWN']) status: string;
 @IsInt() @Min(0) version: number;
}
