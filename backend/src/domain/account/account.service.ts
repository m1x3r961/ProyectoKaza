import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { SupabaseService } from '../../infrastructure/supabase/supabase.service';
@Injectable()
export class AccountService {
  constructor(private readonly db: SupabaseService) {}
  // The RPC refuses admins, hides listings, anonymizes the profile and audits; it is idempotent so a
  // failed Auth step can be retried. Auth is soft-deleted because public tables reference auth.users.
  async deleteOwn(userId: string) {
    const result: any = await this.db.rpc('kaza_delete_own_account', { p_actor: userId });
    if (result?.email) await this.removeAvatars(result.email);
    const { error } = await this.db.client.auth.admin.deleteUser(userId, true);
    if (error) throw new ServiceUnavailableException('No se pudo cerrar la cuenta de acceso. ' + error.message);
    return { success: true, affectedListings: result?.affectedListings ?? 0 };
  }
  // Avatars are uploaded under avatars/<email>/; losing them must not block the deletion.
  private async removeAvatars(email: string) {
    try {
      const bucket = this.db.client.storage.from('avatars');
      const { data } = await bucket.list(email, { limit: 1000 });
      const paths = (data || []).map(file => `${email}/${file.name}`);
      if (paths.length) await bucket.remove(paths);
    } catch (error) {
      console.error('Avatar cleanup failed', error);
    }
  }
}
