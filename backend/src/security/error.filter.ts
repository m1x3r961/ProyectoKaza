import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
@Catch()
export class ErrorFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp(); const req = ctx.getRequest(); const res = ctx.getResponse();
    const status = error instanceof HttpException ? error.getStatus() : 500;
    const body = error instanceof HttpException ? error.getResponse() : null;
    const detail = typeof body === 'object' && body ? (body as any).message : body;
    res.status(status).json({ code: `HTTP_${status}`, message: status >= 500 ? 'No se pudo completar la operación.' : detail, requestId: req.requestId });
  }
}
