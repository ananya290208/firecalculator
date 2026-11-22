import 'dart:convert';
import 'fire_inputs.dart';

/// Represents a snapshot of user-attempted combination for the Comparison tab
class SavedCombination {
  final String id;
  final String title;
  final DateTime timestamp;
  final FireInputs inputs;
  final double projectedCorpusCrores;
  final double surplus25xCrores;
  final double surplus30xCrores;
  final double estPostTaxCorpusCrores;

  const SavedCombination({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.inputs,
    required this.projectedCorpusCrores,
    required this.surplus25xCrores,
    required this.surplus30xCrores,
    required this.estPostTaxCorpusCrores,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'inputs': inputs.toMap(),
      'projectedCorpusCrores': projectedCorpusCrores,
      'surplus25xCrores': surplus25xCrores,
      'surplus30xCrores': surplus30xCrores,
      'estPostTaxCorpusCrores': estPostTaxCorpusCrores,
    };
  }

  factory SavedCombination.fromMap(Map<String, dynamic> map) {
    return SavedCombination(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? 'Simulation',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      inputs: FireInputs.fromMap(map['inputs'] as Map<String, dynamic>? ?? {}),
      projectedCorpusCrores: (map['projectedCorpusCrores'] as num?)?.toDouble() ?? 0.0,
      surplus25xCrores: (map['surplus25xCrores'] as num?)?.toDouble() ?? 0.0,
      surplus30xCrores: (map['surplus30xCrores'] as num?)?.toDouble() ?? 0.0,
      estPostTaxCorpusCrores: (map['estPostTaxCorpusCrores'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedCombination.fromJson(String source) =>
      SavedCombination.fromMap(json.decode(source) as Map<String, dynamic>);
}
