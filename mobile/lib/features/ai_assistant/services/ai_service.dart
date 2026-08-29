import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/supabase_config.dart';

/// Constantes de configuración del servicio AI
class AiConfig {
  /// API Key de Google Gemini (inyectada via --dart-define=GEMINI_API_KEY=xxx)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// API Key de Carto (inyectada via --dart-define=CARTO_API_KEY=xxx)
  static const String cartoApiKey = String.fromEnvironment(
    'CARTO_API_KEY',
    defaultValue: '',
  );
}

/// Mensaje del historial de chat
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

/// Servicio que llama a Google Gemini con contexto de propiedades Kaza
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Obtiene un resumen de propiedades disponibles en Supabase
  Future<String> _fetchPropertiesContext() async {
    try {
      final response = await SupabaseConfig.client
          .from('properties')
          .select(
            'id, property_type, city_id, address_canonical, total_surface_m2, rooms, bathrooms, parking_spaces',
          )
          .limit(30);

      if (response.isEmpty) return 'No hay propiedades disponibles actualmente.';

      final buffer = StringBuffer();
      buffer.writeln('PROPIEDADES EN KAZA (${response.length} en la plataforma):');
      for (final row in response) {
        final type = row['property_type'] ?? 'Propiedad';
        final city = row['city_id'] ?? 'Bolivia';
        final address = row['address_canonical'] ?? 'Sin dirección';
        final surface = row['total_surface_m2'];
        final rooms = row['rooms'] ?? 0;
        final baths = row['bathrooms'] ?? 0;
        buffer.writeln(
          '- $type en $city | $address | ${surface != null ? '$surface m²' : ''} | $rooms hab. | $baths baños',
        );
      }
      return buffer.toString();
    } catch (e) {
      return 'Datos de mercado temporalmente no disponibles.';
    }
  }

  /// Obtiene estadísticas de listings activos
  Future<String> _fetchListingsContext() async {
    try {
      final response = await SupabaseConfig.client
          .from('listings')
          .select('title, price_original, currency_original, status, description')
          .eq('status', 'AVAILABLE')
          .limit(20);

      if (response.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('\nANUNCIOS ACTIVOS EN KAZA (${response.length}):');
      for (final row in response) {
        final title = row['title'] ?? 'Anuncio';
        final price = row['price_original'];
        final currency = row['currency_original'] ?? 'USD';
        final desc = row['description'] as String?;
        final descShort = desc != null && desc.isNotEmpty
            ? ' | ${desc.substring(0, desc.length.clamp(0, 80))}...'
            : '';
        buffer.writeln(
          '- $title | ${price != null ? '$currency $price' : 'Precio a consultar'}$descShort',
        );
      }
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  /// System prompt especializado en mercado inmobiliario boliviano
  String _buildSystemPrompt(String propertiesContext, String listingsContext) {
    return '''Eres Imagina, el asistente inteligente de KAZA — la plataforma de bienes raíces líder en Bolivia.

Tu misión es ayudar a compradores, vendedores e inversores a tomar mejores decisiones inmobiliarias con datos reales y análisis experto del mercado boliviano.

CONTEXTO DE MERCADO EN TIEMPO REAL:
$propertiesContext
$listingsContext

INFORMACIÓN SOBRE EL MAPA Y DATOS:
- Usamos tecnología CARTO (plataforma líder en análisis geoespacial) integrada en nuestro mapa interactivo
- Tenemos datos georreferenciados de propiedades en Bolivia con coordenadas precisas
- La plataforma KAZA opera en Bolivia con foco en Santa Cruz de la Sierra

REGLAS:
1. Responde siempre en español boliviano natural y amigable
2. Sé conciso pero informativo — máximo 3-4 párrafos por respuesta
3. Cuando des estimaciones de precio, indica que son orientativas
4. Si la pregunta no está relacionada con inmobiliaria boliviana, redirige gentilmente
5. Usa los datos de propiedades y anuncios cuando sean relevantes
6. Menciona barrios y zonas bolivianas reales (Equipetrol, Las Palmas, Plan 3000, Zona Norte, etc.)
7. NUNCA inventes datos específicos de propiedades que no estén en tu contexto

Siempre añade al final de cada respuesta: "⚠️ Esta información es orientativa. Verifica siempre con un profesional."''';
  }

  /// Envía un mensaje al LLM de Gemini y retorna la respuesta
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final propertiesContext = await _fetchPropertiesContext();
    final listingsContext = await _fetchListingsContext();
    final systemPrompt = _buildSystemPrompt(propertiesContext, listingsContext);

    // Historial (últimos 8 mensajes para no sobrepasar límites)
    final List<Map<String, dynamic>> contents = [];
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    for (final msg in recentHistory) {
      if (!msg.isError) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text}
          ],
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 800,
      },
    };

    final uri = Uri.parse(
      '${AiConfig.geminiEndpoint}?key=${AiConfig.geminiApiKey}',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String? ??
              'No pude generar una respuesta.';
        }
      }
      return 'No pude procesar la respuesta del asistente.';
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMsg =
          errorBody['error']?['message'] ?? 'Error desconocido';
      throw Exception('Error ${response.statusCode}: $errorMsg');
    }
  }
}
