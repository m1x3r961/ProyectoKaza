import { CanActivate, ExecutionContext, HttpException, Injectable } from '@nestjs/common';
// Per-process burst protection. A shared limiter is required before multi-instance scaling.
@Injectable()
export class RateGuard implements CanActivate {
  private windows = new Map<string, { count: number; until: number }>();
  canActivate(ctx: ExecutionContext) {
    const req = ctx.switchToHttp().getRequest(); const now = Date.now();
    const ai = req.path.startsWith('/api/ai'); const limit = ai ? 10 : 120;
    for (const [key, value] of this.windows) if (value.until <= now) this.windows.delete(key);
    const key = `${req.actor?.id || req.ip}:${ai ? 'ai' : 'api'}`;
    const current = this.windows.get(key) || { count: 0, until: now + 60000 };
    if (this.windows.size >= 10000 && !this.windows.has(key)) throw new HttpException('Intenta más tarde.', 429);
    current.count++; this.windows.set(key, current);
    if (current.count > limit) throw new HttpException('Demasiadas solicitudes. Intenta en un minuto.', 429);
    return true;
  }
}
