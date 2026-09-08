import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/collaboration_models.dart';
import '../providers/collaboration_provider.dart';

class CollaborationFlowScreen extends ConsumerStatefulWidget {
  const CollaborationFlowScreen({super.key});

  @override
  ConsumerState<CollaborationFlowScreen> createState() => _CollaborationFlowScreenState();
}

class _CollaborationFlowScreenState extends ConsumerState<CollaborationFlowScreen> {
  int _currentStep = 2; // Starts at 02 Invitar a colaborar

  @override
  void initState() {
    super.initState();
    // Initialize draft on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collaborationProvider.notifier).startNewCollaboration('prop_1', 'Casa moderna en Equipetrol Norte', 185000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collaborationProvider);
    final draft = state.currentDraft;

    if (draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KazaTheme.textPrimary),
          onPressed: () {
            if (_currentStep > 2) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_getStepTitle(), style: const TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _buildStepContent(draft),
      bottomNavigationBar: _buildBottomButton(draft),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 2: return 'Invitar a colaborar';
      case 3: return 'Definir colaboración';
      case 4: return 'Invitación enviada';
      case 5: return 'Colaboración activa';
      case 6: return 'Operación conjunta';
      case 7: return 'Cierre y comisión';
      default: return '';
    }
  }

  Widget _buildStepContent(Collaboration draft) {
    switch (_currentStep) {
      case 2: return _buildStep02Invite();
      case 3: return _buildStep03Define(draft);
      case 4: return _buildStep04Sent();
      case 5: return _buildStep05Active();
      case 6: return _buildStep06Operation();
      case 7: return _buildStep07Closing(draft);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButton(Collaboration draft) {
    String btnText = '';
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 2:
        btnText = 'Continuar';
        onPressed = () {
          ref.read(collaborationProvider.notifier).addInvitee('u2', 'Carlos Suárez', 'Co-corredor');
          setState(() => _currentStep = 3);
        };
        break;
      case 3:
        btnText = 'Enviar Invitación';
        onPressed = () {
          ref.read(collaborationProvider.notifier).sendInvitation();
          setState(() => _currentStep = 4);
        };
        break;
      case 4:
        btnText = 'Ver Detalles';
        onPressed = () {
          ref.read(collaborationProvider.notifier).acceptInvitationMock();
          setState(() => _currentStep = 5);
        };
        break;
      case 5:
        btnText = 'Ver Detalles';
        onPressed = () => setState(() => _currentStep = 6);
        break;
      case 6:
        btnText = 'Ver operación';
        onPressed = () {
          ref.read(collaborationProvider.notifier).closeOperationMock();
          setState(() => _currentStep = 7);
        };
        break;
      case 7:
        btnText = 'Ver comprobante';
        onPressed = () => context.pop();
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- STEPS BUILDERS ---

  Widget _buildStep02Invite() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por usuario o correo',
            prefixIcon: const Icon(Icons.search, color: KazaTheme.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Sugerencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildUserListTile('Carlos Suárez', 'Corredor Inmobiliario', true),
        _buildUserListTile('Ana Ruiz', 'Agente', false),
        _buildUserListTile('María Gil', 'Desarrolladora', false),
      ],
    );
  }

  Widget _buildUserListTile(String name, String role, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: selected ? Colors.black : KazaTheme.glassBorder, width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: KazaTheme.n100, child: Icon(Icons.person, color: KazaTheme.textMuted)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role, style: const TextStyle(fontSize: 12)),
        trailing: selected ? const Icon(Icons.check_circle, color: Colors.black) : null,
      ),
    );
  }

  Widget _buildStep03Define(Collaboration draft) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Modo de colaboración', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: KazaTheme.glassBorder), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Co-corretaje', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down)
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Alcance', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: KazaTheme.glassBorder), borderRadius: BorderRadius.circular(12)),
          child: const Text('Comercialización completa'),
        ),
        const SizedBox(height: 24),
        const Text('Reparto de comisión', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: KazaTheme.n100, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Text('Tú', style: TextStyle(color: KazaTheme.textSecondary)),
                    Text('50%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: KazaTheme.n100, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Text('Carlos Suárez', style: TextStyle(color: KazaTheme.textSecondary)),
                    Text('50%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Generar acuerdo automáticamente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          value: true,
          onChanged: (val) {},
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildStep04Sent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send_outlined, size: 64, color: KazaTheme.textMuted),
          const SizedBox(height: 24),
          const Text('Invitación enviada a\nCarlos Suárez', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('Pendiente de aceptación', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildStep05Active() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.handshake_outlined, size: 64, color: KazaTheme.verifiedGreen),
          const SizedBox(height: 24),
          const Text('Colaboración\nActiva', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: KazaTheme.glassBorder), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                CircleAvatar(backgroundColor: KazaTheme.n100, child: Icon(Icons.person, color: KazaTheme.textMuted)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Carlos Suárez', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Co-corredor', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: KazaTheme.verifiedGreen),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep06Operation() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Etapas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildMilestone('Contacto', true),
        _buildMilestone('Visita', true),
        _buildMilestone('Negociación', true),
        _buildMilestone('Cierre', false),
        const SizedBox(height: 32),
        const Text('Participantes activos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildUserListTile('Jorge Vigo', 'Propietario', false),
        _buildUserListTile('Carlos Suárez', 'Co-corredor', false),
      ],
    );
  }

  Widget _buildMilestone(String title, bool completed) {
    return Row(
      children: [
        Column(
          children: [
            Icon(completed ? Icons.check_circle : Icons.circle_outlined, color: completed ? KazaTheme.verifiedGreen : KazaTheme.glassBorder),
            Container(height: 30, width: 2, color: KazaTheme.glassBorder),
          ],
        ),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(fontWeight: completed ? FontWeight.bold : FontWeight.normal, color: completed ? KazaTheme.textPrimary : KazaTheme.textSecondary)),
      ],
    );
  }

  Widget _buildStep07Closing(Collaboration draft) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.celebration, size: 48, color: KazaTheme.verifiedGreen),
        const SizedBox(height: 16),
        const Text('Operación Cerrada', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Center(child: Text('Venta completada', style: TextStyle(color: KazaTheme.verifiedGreen, fontWeight: FontWeight.bold))),
        const SizedBox(height: 32),
        const Text('Valor de venta', style: TextStyle(color: KazaTheme.textSecondary)),
        const Text('\$ 185.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Comisión total (5%)', style: TextStyle(color: KazaTheme.textSecondary)),
        const Text('\$ 9.250', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 24),
        const Text('Reparto acordado', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Carlos Suárez (50%)'),
            Text('\$ ${9250 / 2}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tú (50%)'),
            Text('\$ ${9250 / 2}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
