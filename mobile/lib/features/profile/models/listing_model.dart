class ListingModel {
  final String id;
  final String title;
  final String? description;
  final double? priceOriginal;
  final String? currencyOriginal;
  final String status;
  final DateTime? freshnessConfirmedAt;

  ListingModel({
    required this.id,
    required this.title,
    this.description,
    this.priceOriginal,
    this.currencyOriginal,
    required this.status,
    this.freshnessConfirmedAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceOriginal: json['price_original'] != null ? (json['price_original'] as num).toDouble() : null,
      currencyOriginal: json['currency_original'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      freshnessConfirmedAt: json['freshness_confirmed_at'] != null ? DateTime.tryParse(json['freshness_confirmed_at']) : null,
    );
  }

  // Format price
  String get formattedPrice {
    if (priceOriginal == null) return 'Consultar';
    final currency = currencyOriginal ?? 'USD';
    final priceStr = priceOriginal!.toStringAsFixed(0);
    // Add thousand separators manually for simplicity, or just use string
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = priceStr.replaceAllMapped(regex, (Match m) => '${m[1]}.');
    
    if (currency == 'USD') return 'USD $formatted';
    if (currency == 'BOB') return 'Bs. $formatted';
    return '$currency $formatted';
  }
}
