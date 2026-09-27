import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
export const Public = () => SetMetadata('public', true);
export const Admin = () => SetMetadata('admin', true);
export const DemoOnly = () => SetMetadata('demo', true);
export interface Actor { id: string; token: string; aal: string; }
export const CurrentActor = createParamDecorator((_: unknown, ctx: ExecutionContext): Actor => ctx.switchToHttp().getRequest().actor);
