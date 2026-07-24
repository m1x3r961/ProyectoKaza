import { Controller, Post, Patch, Body, Param, Headers, UsePipes, ValidationPipe } from '@nestjs/common';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { TransferControllerDto } from './dto/transfer-controller.dto';
import { UpdateListingStatusDto } from './dto/update-status.dto';

@Controller('api/listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  /// POST /api/listings
  /// Publicación formal de inmuebles mediante el Guardián de Dominio
  @Post()
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async createListing(
    @Headers('x-user-id') userId: string = 'usr-demo-operator',
    @Body() dto: CreateListingDto,
  ) {
    return this.listingsService.createListing(userId, dto);
  }

  /// POST /api/listings/:id/transfer-controller
  /// Transferencia bilateral de Controller entre Workspaces
  @Post(':id/transfer-controller')
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async transferController(
    @Param('id') listingId: string,
    @Headers('x-user-id') userId: string = 'usr-demo-operator',
    @Body() dto: TransferControllerDto,
  ) {
    return this.listingsService.transferController(listingId, userId, dto);
  }

  /// PATCH /api/listings/:id/status
  /// Transición controlada en la máquina de estados del Listing
  @Patch(':id/status')
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async updateStatus(
    @Param('id') listingId: string,
    @Body() dto: UpdateListingStatusDto,
  ) {
    return this.listingsService.updateStatus(listingId, dto);
  }
}
