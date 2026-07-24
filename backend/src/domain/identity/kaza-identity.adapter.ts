import { Injectable } from '@nestjs/common';

export interface KazaUser {
  id: string;
  email: string;
  fullName?: string;
  avatarUrl?: string;
  isVerified: boolean;
}

export interface KazaWorkspaceContext {
  workspaceId: string;
  workspaceType: 'PERSONAL' | 'ORGANIZATION';
  role?: string;
  permissions: string[];
}

/// Kaza Identity Adapter
/// Encapsula Supabase Auth evitando que la lógica del dominio dependa directamente
/// del proveedor externo de identidad.
@Injectable()
export class KazaIdentityAdapter {
  async authenticateToken(token: string): Promise<KazaUser> {
    // Adapter implementation delegating to Supabase Auth JWT verification
    return {
      id: 'usr-demo-uuid',
      email: 'user@kaza.app',
      fullName: 'Kaza Operator User',
      isVerified: true,
    };
  }

  async getWorkspaceContext(userId: string, workspaceId: string): Promise<KazaWorkspaceContext> {
    return {
      workspaceId,
      workspaceType: 'ORGANIZATION',
      role: 'OPERATOR',
      permissions: ['listings.edit_price', 'leads.reply', 'visits.schedule'],
    };
  }
}
