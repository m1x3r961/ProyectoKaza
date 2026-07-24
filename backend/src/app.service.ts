import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: 'ok',
      service: 'Kaza NestJS Domain Guardian Backend',
      version: '0.2.0',
      timestamp: new Date().toISOString(),
      architecture: 'Flutter + NestJS + Supabase + Next.js Admin',
    };
  }
}
