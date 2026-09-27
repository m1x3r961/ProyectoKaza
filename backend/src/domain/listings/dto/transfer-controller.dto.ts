import { IsUUID, IsInt, Min } from 'class-validator';
export class TransferControllerDto {
 @IsUUID() targetWorkspaceId: string;
 @IsUUID() newOperatorUserId: string;
 @IsInt() @Min(0) version: number;
}
