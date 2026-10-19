import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { Equals } from 'class-validator';
import { Actor, AllowDeleted, CurrentActor } from '../../security/access';
import { AccountService } from './account.service';
class DeleteAccountDto { @Equals('ELIMINAR') confirm: string; }
@Controller('api/account')
export class AccountController {
  constructor(private readonly account: AccountService) {}
  @Post('delete') @HttpCode(200) @AllowDeleted()
  delete(@CurrentActor() a: Actor, @Body() _dto: DeleteAccountDto) { return this.account.deleteOwn(a.id); }
}
