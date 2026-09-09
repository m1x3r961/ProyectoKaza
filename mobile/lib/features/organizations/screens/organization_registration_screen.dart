import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/kaza_theme.dart';
import '../providers/organizations_provider.dart';

class OrganizationRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizationRegistrationScreen> createState() => _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState extends ConsumerState<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  int _currentStep = 0;
  final int _totalSteps = 3;

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
    _pageController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido.')));
      return;
    }
    
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Mismo fondo que el resto del CRM
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildGlassmorphismContainer(
                        child: Form(
                          key: _formKey,
                          child: SizedBox(
                            height: 400,
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStep1(),
                                _buildStep2(),
                                _buildStep3(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        children: [
          const Icon(Icons.business, color: KazaTheme.azulKaza, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Registrar Desarrolladora',
              style: TextStyle(color: KazaTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? KazaTheme.coralKaza : KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGlassmorphismContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KazaTheme.azulKaza.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: KazaTheme.azulKaza.withOpacity(0.05),
                blurRadius: 24,
                spreadRadius: -5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Información General', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 8),
        Text('Cuéntanos sobre tu empresa.', style: TextStyle(fontSize: 14, color: KazaTheme.textMuted)),
        const SizedBox(height: 32),
        _buildTextField(_nameController, 'Nombre Legal o Comercial', icon: Icons.apartment, isRequired: true),
        const SizedBox(height: 24),
        _buildTextField(_descController, 'Breve descripción de la empresa', maxLines: 4, icon: Icons.description),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Contacto e Identidad', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 8),
        Text('¿Cómo pueden contactarte los clientes?', style: TextStyle(fontSize: 14, color: KazaTheme.textMuted)),
        const SizedBox(height: 32),
        _buildTextField(_websiteController, 'Sitio web', icon: Icons.language),
        const SizedBox(height: 24),
        _buildTextField(_emailController, 'Correo corporativo', icon: Icons.email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 24),
        _buildTextField(_phoneController, 'Teléfono principal', icon: Icons.phone, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. Ubicación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 8),
        Text('¿Dónde se encuentran tus oficinas?', style: TextStyle(fontSize: 14, color: KazaTheme.textMuted)),
        const SizedBox(height: 32),
        _buildTextField(_cityController, 'Ciudad', icon: Icons.location_city),
        const SizedBox(height: 24),
        _buildTextField(_addressController, 'Dirección completa', maxLines: 3, icon: Icons.map),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, bool isRequired = false, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: KazaTheme.textPrimary),
      validator: isRequired
          ? (value) => value == null || value.isEmpty ? 'Requerido' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: KazaTheme.textMuted),
        prefixIcon: icon != null ? Icon(icon, color: KazaTheme.textMuted) : null,
        filled: true,
        fillColor: KazaTheme.grisClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: KazaTheme.azulKaza.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KazaTheme.coralKaza, width: 2),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: KazaTheme.azulKaza.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Atrás', style: TextStyle(color: KazaTheme.azulKaza, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.coralKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: KazaTheme.coralKaza.withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == _totalSteps - 1 ? 'Crear Empresa' : 'Siguiente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
