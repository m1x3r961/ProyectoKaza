import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/kaza_theme.dart';
import '../providers/organizations_provider.dart';

class OrganizationRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizationRegistrationScreen> createState() => _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState extends ConsumerState<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final err = await ref.read(organizationsProvider.notifier).createOrganization(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      orgType: 'DEVELOPER', // Siempre DEVELOPER por ahora
    );

    setState(() => _isLoading = false);

    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      // Éxito. El provider recargará la lista de organizaciones.
      // El dashboard padre detectará que ya hay organización y cambiará de vista automáticamente.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registrar Desarrolladora', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información General'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Nombre de la empresa (Legal o Comercial)', isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(_descController, 'Descripción breve', maxLines: 3),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Contacto e Identidad'),
              const SizedBox(height: 16),
              _buildTextField(_websiteController, 'Sitio web (ej. www.miempresa.com)'),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Correo de contacto corporativo'),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Teléfono principal'),

              const SizedBox(height: 32),
              _buildSectionTitle('Ubicación'),
              const SizedBox(height: 16),
              _buildTextField(_cityController, 'Ciudad base'),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Dirección de oficina principal', maxLines: 2),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.coralKaza,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Completar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: isRequired
          ? (value) => value == null || value.isEmpty ? 'Este campo es requerido' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: KazaTheme.textMuted),
        filled: true,
        fillColor: KazaTheme.grisClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KazaTheme.primaryCoral),
        ),
      ),
    );
  }
}
