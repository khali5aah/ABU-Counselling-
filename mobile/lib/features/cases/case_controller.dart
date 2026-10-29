import 'package:flutter/foundation.dart';

import 'models/case_model.dart';
import 'utils/pseudonym_generator.dart';

class CaseController extends ChangeNotifier {
  final List<CaseModel> _cases = [];

  List<CaseModel> get cases => List.unmodifiable(_cases);

  /// Submits a new anonymized case request
  Future<void> createCase({
    required String category,
    required String description,
  }) async {
    final newCase = CaseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pseudonym: PseudonymGenerator.generate(),
      category: category,
      description: description,
      status: CaseStatus.open,
      createdAt: DateTime.now(),
    );

    _cases.insert(0, newCase);
    notifyListeners();
  }
}