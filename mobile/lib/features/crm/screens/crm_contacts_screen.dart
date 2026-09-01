import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/crm_models.dart';

final crmContactsProvider = FutureProvider.autoDispose<List<CrmContact>>((ref) async {
  final auth = ref.watch(kazaAuthProvider);
  if (auth.userId == null) return [];
  
  final response = await SupabaseConfig.client
      .from('crm_contacts')
      .select('*')
      .order('created_at', ascending: false);
      
  return (response as List).map((x) => CrmContact.fromJson(x)).toList();
});

/// 👥 CONTACTOS (CRM U06)
class CrmContactsScreen extends ConsumerStatefulWidget {
  const CrmContactsScreen({super.key});

  @override
  ConsumerState<CrmContactsScreen> createState() => _CrmContactsScreenState();
}

class _CrmContactsScreenState extends ConsumerState<CrmContactsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _addContact() async {
    final auth = ref.read(kazaAuthProvider);
    if (auth.userId == null) return;
    if (_nameCtrl.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.client.from('crm_contacts').insert({
        'agent_id': auth.userId,
        'first_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      _nameCtrl.clear();
      _phoneCtrl.clear();
      ref.invalidate(crmContactsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving contact: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddContactModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Contacto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre y apellido')),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.primaryCoral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _addContact,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(crmContactsProvider);

    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Contactos', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: KazaTheme.azulKaza), onPressed: _showAddContactModal),
        ],
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = contacts[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KazaTheme.glassBorder),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: KazaTheme.n100,
                    child: Text(c.firstName[0].toUpperCase(), style: const TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${c.firstName} ${c.lastName ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(c.phone ?? 'Sin teléfono', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.more_vert, color: KazaTheme.grisMedio),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KazaTheme.primaryCoral,
        onPressed: _showAddContactModal,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts_outlined, size: 80, color: KazaTheme.grisMedio),
          const SizedBox(height: 16),
          const Text('No tienes contactos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Agrega clientes a tu CRM para\nhacer seguimiento.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white),
            onPressed: _showAddContactModal,
            child: const Text('Agregar Contacto'),
          ),
        ],
      ),
    );
  }
}
