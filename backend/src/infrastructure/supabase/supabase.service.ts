import { Injectable, BadRequestException, ConflictException, ForbiddenException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { configuration } from '../../config';
@Injectable()
export class SupabaseService {
  readonly config = configuration();
  readonly client: SupabaseClient = createClient(this.config.url, this.config.serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { fetch: (url, options) => fetch(url, { ...options, signal: AbortSignal.timeout(10000) }) },
  });
  async rpc(name: string, args: Record<string, unknown> = {}) {
    const { data, error } = await this.client.rpc(name, args);
    if (error) {
      if (error.code === '42501') throw new ForbiddenException('No tienes permiso para esta operación.');
      if (error.code === 'P0002') throw new NotFoundException('Recurso no disponible.');
      if (['23505', '40001'].includes(error.code)) throw new ConflictException('El recurso cambió o el intento ya existe. Actualiza e inténtalo nuevamente.');
      if (['22023', '23514', '22P02'].includes(error.code)) throw new BadRequestException('Los datos o la transición no son válidos.');
      throw new ServiceUnavailableException('No se pudo completar la operación.');
    }
    return data;
  }
}
