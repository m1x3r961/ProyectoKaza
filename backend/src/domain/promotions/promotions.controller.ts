import { CurrentActor, Actor } from '../../security/access';
import { Controller, Post, Body, Headers, UsePipes, ValidationPipe } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import { ActivatePlusPromotionDto } from './dto/activate-plus.dto';

@Controller('api/promotions')
export class PromotionsController {
  constructor(private readonly promotionsService: PromotionsService) {}

  /// POST /api/promotions/activate-plus
  /// Activación de promoción Plus verificando transacción de Apple IAP / Google Play / Web
  @Post('activate-plus')
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async activatePlus(
    @CurrentActor() actor: Actor,
    @Body() dto: ActivatePlusPromotionDto,
  ) {
    return this.promotionsService.activatePlus(actor.id, dto);
  }
}
