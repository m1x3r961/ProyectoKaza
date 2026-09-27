import { Injectable, ServiceUnavailableException } from '@nestjs/common';
@Injectable()
export class PromotionsService {
 async activatePlus(_actor: string, _dto: unknown) { throw new ServiceUnavailableException('Los cobros verificados aún no están habilitados.'); }
}
