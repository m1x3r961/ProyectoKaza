import { IsEnum } from 'class-validator';

export enum ListingStatusEnum {
  DRAFT = 'DRAFT',
  REVIEW = 'REVIEW',
  AVAILABLE = 'AVAILABLE',
  RESERVED = 'RESERVED',
  CLOSED = 'CLOSED',
  PAUSED = 'PAUSED',
  WITHDRAWN = 'WITHDRAWN',
}

export class UpdateListingStatusDto {
  @IsEnum(ListingStatusEnum)
  status: ListingStatusEnum;
}
