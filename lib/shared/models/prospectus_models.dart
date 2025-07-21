/// Data models for DIT Prospectus content
library;

class Program {
  final String id;
  final String name;
  final String description;
  final String duration;
  final List<String> requirements;
  final String category;
  final String faculty;
  final double? fee;
  final List<String> careerOpportunities;

  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.requirements,
    required this.category,
    required this.faculty,
    this.fee,
    this.careerOpportunities = const [],
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      category: json['category'] ?? '',
      faculty: json['faculty'] ?? '',
      fee: json['fee']?.toDouble(),
      careerOpportunities: List<String>.from(json['careerOpportunities'] ?? []),
    );
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      category: map['category'] ?? '',
      faculty: map['faculty'] ?? '',
      fee: map['fee']?.toDouble(),
      careerOpportunities: List<String>.from(map['careerOpportunities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'requirements': requirements,
      'category': category,
      'faculty': faculty,
      'fee': fee,
      'careerOpportunities': careerOpportunities,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'requirements': requirements,
      'category': category,
      'faculty': faculty,
      'fee': fee,
      'careerOpportunities': careerOpportunities,
    };
  }

  /// Generate speech-friendly description
  String toSpeechText() {
    final buffer = StringBuffer();
    buffer.write('$name is a $duration program in the $faculty faculty. ');
    buffer.write(description);

    if (requirements.isNotEmpty) {
      buffer.write(' Entry requirements include: ${requirements.join(', ')}.');
    }

    if (fee != null) {
      buffer.write(
        ' The program fee is ${fee!.toStringAsFixed(0)} Tanzanian Shillings per year.',
      );
    }

    if (careerOpportunities.isNotEmpty) {
      buffer.write(
        ' Career opportunities include: ${careerOpportunities.join(', ')}.',
      );
    }

    return buffer.toString();
  }
}

class FeeStructure {
  final String id;
  final String programId;
  final String programName;
  final double tuitionFee;
  final double registrationFee;
  final double examinationFee;
  final double otherFees;
  final String currency;
  final List<PaymentOption> paymentOptions;

  FeeStructure({
    required this.id,
    required this.programId,
    required this.programName,
    required this.tuitionFee,
    required this.registrationFee,
    required this.examinationFee,
    required this.otherFees,
    this.currency = 'TZS',
    this.paymentOptions = const [],
  });

  double get totalFee =>
      tuitionFee + registrationFee + examinationFee + otherFees;

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json['id'] ?? '',
      programId: json['programId'] ?? '',
      programName: json['programName'] ?? '',
      tuitionFee: (json['tuitionFee'] ?? 0).toDouble(),
      registrationFee: (json['registrationFee'] ?? 0).toDouble(),
      examinationFee: (json['examinationFee'] ?? 0).toDouble(),
      otherFees: (json['otherFees'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TZS',
      paymentOptions:
          (json['paymentOptions'] as List<dynamic>?)
              ?.map((e) => PaymentOption.fromJson(e))
              .toList() ??
          [],
    );
  }

  factory FeeStructure.fromMap(Map<String, dynamic> map) {
    return FeeStructure(
      id: map['id'] ?? '',
      programId: map['programId'] ?? '',
      programName: map['programName'] ?? '',
      tuitionFee: (map['tuitionFee'] ?? 0).toDouble(),
      registrationFee: (map['registrationFee'] ?? 0).toDouble(),
      examinationFee: (map['examinationFee'] ?? 0).toDouble(),
      otherFees: (map['otherFees'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TZS',
      paymentOptions: [], // Simplified for Firestore storage
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'tuitionFee': tuitionFee,
      'registrationFee': registrationFee,
      'examinationFee': examinationFee,
      'otherFees': otherFees,
      'currency': currency,
      'paymentOptions': paymentOptions.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'tuitionFee': tuitionFee,
      'registrationFee': registrationFee,
      'examinationFee': examinationFee,
      'otherFees': otherFees,
      'currency': currency,
      'paymentOptions': [], // Simplified for Firestore storage
    };
  }

  /// Generate speech-friendly fee description
  String toSpeechText() {
    final buffer = StringBuffer();
    buffer.write('For $programName, the fee structure is as follows: ');
    buffer.write('Tuition fee is ${tuitionFee.toStringAsFixed(0)} $currency. ');

    if (registrationFee > 0) {
      buffer.write(
        'Registration fee is ${registrationFee.toStringAsFixed(0)} $currency. ',
      );
    }

    if (examinationFee > 0) {
      buffer.write(
        'Examination fee is ${examinationFee.toStringAsFixed(0)} $currency. ',
      );
    }

    if (otherFees > 0) {
      buffer.write(
        'Other fees amount to ${otherFees.toStringAsFixed(0)} $currency. ',
      );
    }

    buffer.write(
      'The total fee is ${totalFee.toStringAsFixed(0)} $currency per year. ',
    );

    if (paymentOptions.isNotEmpty) {
      buffer.write('Payment options include: ');
      buffer.write(
        paymentOptions.map((option) => option.description).join(', '),
      );
      buffer.write('.');
    }

    return buffer.toString();
  }
}

class PaymentOption {
  final String id;
  final String name;
  final String description;
  final int installments;
  final List<String> deadlines;

  PaymentOption({
    required this.id,
    required this.name,
    required this.description,
    required this.installments,
    this.deadlines = const [],
  });

  factory PaymentOption.fromJson(Map<String, dynamic> json) {
    return PaymentOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      installments: json['installments'] ?? 1,
      deadlines: List<String>.from(json['deadlines'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'installments': installments,
      'deadlines': deadlines,
    };
  }
}

class AdmissionInfo {
  final String id;
  final String title;
  final String description;
  final List<String> generalRequirements;
  final List<String> procedures;
  final List<String> documents;
  final List<String> deadlines;
  final String contactInfo;

  AdmissionInfo({
    required this.id,
    required this.title,
    required this.description,
    this.generalRequirements = const [],
    this.procedures = const [],
    this.documents = const [],
    this.deadlines = const [],
    this.contactInfo = '',
  });

  factory AdmissionInfo.fromJson(Map<String, dynamic> json) {
    return AdmissionInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      generalRequirements: List<String>.from(json['generalRequirements'] ?? []),
      procedures: List<String>.from(json['procedures'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      deadlines: List<String>.from(json['deadlines'] ?? []),
      contactInfo: json['contactInfo'] ?? '',
    );
  }

  factory AdmissionInfo.fromMap(Map<String, dynamic> map) {
    return AdmissionInfo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      generalRequirements: List<String>.from(map['generalRequirements'] ?? []),
      procedures: List<String>.from(map['procedures'] ?? []),
      documents: List<String>.from(map['documents'] ?? []),
      deadlines: List<String>.from(map['deadlines'] ?? []),
      contactInfo: map['contactInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'generalRequirements': generalRequirements,
      'procedures': procedures,
      'documents': documents,
      'deadlines': deadlines,
      'contactInfo': contactInfo,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'generalRequirements': generalRequirements,
      'procedures': procedures,
      'documents': documents,
      'deadlines': deadlines,
      'contactInfo': contactInfo,
    };
  }

  /// Generate speech-friendly admission description
  String toSpeechText() {
    final buffer = StringBuffer();
    buffer.write('$title. $description ');

    if (generalRequirements.isNotEmpty) {
      buffer.write(
        'General requirements are: ${generalRequirements.join(', ')}. ',
      );
    }

    if (procedures.isNotEmpty) {
      buffer.write('Application procedures: ${procedures.join(', ')}. ');
    }

    if (documents.isNotEmpty) {
      buffer.write('Required documents include: ${documents.join(', ')}. ');
    }

    if (deadlines.isNotEmpty) {
      buffer.write('Important deadlines: ${deadlines.join(', ')}. ');
    }

    if (contactInfo.isNotEmpty) {
      buffer.write('For more information, contact: $contactInfo.');
    }

    return buffer.toString();
  }
}

class ProspectusContent {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime lastUpdated;
  final List<String> tags;

  ProspectusContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.lastUpdated,
    this.tags = const [],
  });

  factory ProspectusContent.fromJson(Map<String, dynamic> json) {
    return ProspectusContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  factory ProspectusContent.fromMap(Map<String, dynamic> map) {
    return ProspectusContent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      lastUpdated: map['lastUpdated'] is DateTime
          ? map['lastUpdated']
          : DateTime.parse(
              map['lastUpdated'] ?? DateTime.now().toIso8601String(),
            ),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'lastUpdated': lastUpdated.toIso8601String(),
      'tags': tags,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'lastUpdated': lastUpdated,
      'tags': tags,
    };
  }

  /// Generate speech-friendly content
  String toSpeechText() {
    return '$title. $content';
  }
}
