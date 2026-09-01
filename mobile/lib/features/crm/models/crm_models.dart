class CrmContact {
  final String id;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? notes;

  CrmContact({
    required this.id,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.notes,
  });

  factory CrmContact.fromJson(Map<String, dynamic> json) {
    return CrmContact(
      id: json['id'],
      firstName: json['first_name'] ?? 'Sin nombre',
      lastName: json['last_name'],
      phone: json['phone'],
      email: json['email'],
      notes: json['notes'],
    );
  }
}

class CrmOpportunity {
  final String id;
  final String title;
  final String stage;
  final double amountExpected;
  final String? contactId;
  final CrmContact? contact;

  CrmOpportunity({
    required this.id,
    required this.title,
    required this.stage,
    this.amountExpected = 0.0,
    this.contactId,
    this.contact,
  });

  factory CrmOpportunity.fromJson(Map<String, dynamic> json) {
    return CrmOpportunity(
      id: json['id'],
      title: json['title'] ?? 'Sin título',
      stage: json['stage'] ?? 'PROSPECTO',
      amountExpected: (json['amount_expected'] ?? 0).toDouble(),
      contactId: json['contact_id'],
      contact: json['crm_contacts'] != null ? CrmContact.fromJson(json['crm_contacts']) : null,
    );
  }
}

class CrmTask {
  final String id;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;

  CrmTask({
    required this.id,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
  });

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    return CrmTask(
      id: json['id'],
      title: json['title'] ?? 'Sin título',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
