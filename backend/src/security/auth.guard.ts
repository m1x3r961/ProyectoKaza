import { CanActivate, ExecutionContext, Injectable, UnauthorizedException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SupabaseService } from '../infrastructure/supabase/supabase.service';
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly db: SupabaseService) {}
  async canActivate(context: ExecutionContext) {
    const targets = [context.getHandler(), context.getClass()];
    if (this.reflector.getAllAndOverride('public', targets)) return true;
    if (this.reflector.getAllAndOverride('demo', targets) && !this.db.config.demo) throw new NotFoundException();
    const req = context.switchToHttp().getRequest();
    const match = /^Bearer ([^\s]+)$/i.exec(req.headers.authorization || '');
    if (!match) throw new UnauthorizedException('Inicia sesión.');
    const token = match[1];
    // Supabase Auth verifies the token before any decoded claim is trusted.
    const { data, error } = await this.db.client.auth.getUser(token);
    if (error || !data.user) throw new UnauthorizedException('La sesión no es válida.');
    let claims: any;
    try { claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()); } catch { throw new UnauthorizedException(); }
    const aud = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    if (claims.sub !== data.user.id || claims.iss !== `${this.db.config.url}/auth/v1` || !aud.includes('authenticated') || !Number.isFinite(claims.exp) || claims.exp <= Date.now()/1000) throw new UnauthorizedException();
    const { data: profile, error: profileError } = await this.db.client.from('profiles').select('status').eq('id', data.user.id).maybeSingle();
    if (profileError) throw new ForbiddenException('No se pudo verificar el estado de la cuenta.');
    if (profile && profile.status !== 'ACTIVE') throw new ForbiddenException('Cuenta restringida.');
    req.actor = { id: data.user.id, token, aal: claims.aal };
    if (this.reflector.getAllAndOverride('admin', targets)) {
      const google = data.user.app_metadata?.provider === 'google'
        && data.user.identities?.some(identity => identity.provider === 'google')
        && Array.isArray(claims.amr) && claims.amr.some(method => method.method === 'oauth');
      if (!google) throw new ForbiddenException('Entra con Google para acceder al administrador.');
      if (this.reflector.getAllAndOverride('adminBootstrap', targets)) {
        const granted = await this.db.rpc('kaza_claim_initial_admin', { p_actor: data.user.id });
        if (!granted) throw new ForbiddenException('Este panel ya tiene un administrador. Entra con la cuenta registrada.');
      }
      const { data: admin, error: adminError } = await this.db.client.from('kaza_admins').select('user_id').eq('user_id', data.user.id).maybeSingle();
      if (adminError || !admin) throw new ForbiddenException('Acceso administrativo requerido.');
    }
    return true;
  }
}
