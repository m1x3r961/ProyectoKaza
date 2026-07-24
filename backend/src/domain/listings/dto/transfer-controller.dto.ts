import { IsString, IsOptional } from 'class-validator';

export class TransferControllerDto {
  @IsString()
  targetWorkspaceId: string;

  @IsString()
  newOperatorUserId: string;

  @IsString()
  @IsOptional()
  transferNotes?: string;
}
