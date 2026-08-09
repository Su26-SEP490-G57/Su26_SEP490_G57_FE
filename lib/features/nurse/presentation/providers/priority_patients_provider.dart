import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/nurse/domain/models/patient_summary.dart';
import 'package:poms/features/nurse/presentation/providers/patient_provider.dart';

// A family provider to fetch patients based on search and optional level filter
// We will use this to fetch Red and Yellow separately if needed.
final patientsQueryProvider = FutureProvider.autoDispose
    .family<List<PatientSummary>, PatientsQuery>((ref, query) async {
      final repository = ref.watch(patientRepositoryProvider);
      // repository.getPatients returns a PatientPage; extract the list of PatientSummary
      final page = await repository.getPatients(
        search: query.search,
        level: query.level,
        limit: query.limit,
      );

      return page.patients;
    });

class PatientsQuery {
  final String? search;
  final String? level;
  final int limit;

  // ignore: sort_constructors_first
  const PatientsQuery({this.search, this.level, this.limit = 50});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientsQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          level == other.level &&
          limit == other.limit;

  @override
  int get hashCode => search.hashCode ^ level.hashCode ^ limit.hashCode;
}

// State provider for the priority patients screen's search text
final priorityPatientsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

// The main provider for priority patients that fetches both Red and Yellow and merges them
final priorityPatientsProvider =
    FutureProvider.autoDispose<List<PatientSummary>>((ref) async {
      final searchQuery = ref.watch(priorityPatientsSearchQueryProvider);

      // Fetch both Red and Yellow patients concurrently
      final redPatientsAsync = ref.watch(
        patientsQueryProvider(
          PatientsQuery(search: searchQuery, level: 'Red', limit: 50),
        ).future,
      );
      final yellowPatientsAsync = ref.watch(
        patientsQueryProvider(
          PatientsQuery(search: searchQuery, level: 'Yellow', limit: 50),
        ).future,
      );

      final results = await Future.wait([
        redPatientsAsync,
        yellowPatientsAsync,
      ]);

      final combined = [...results[0], ...results[1]];

      // They are implicitly sorted because we add Red then Yellow.
      // We can further sort them by POD or other rules if needed.

      return combined;
    });
