import 'package:flutter/material.dart';

import '../domain/sighting.dart';
import '../domain/sightings_repository.dart';

/// Static seed data — sightings has no backend yet, so this stands in for
/// [MockSightingsRepository.fetchSightings] until one exists.
class MockSightingsRepository implements SightingsRepository {
  @override
  Future<List<Sighting>> fetchSightings() async {
    return _mockSightings;
  }
}

final _mockSightings = <Sighting>[
  Sighting(
    id: 's1',
    animal: Species.cat,
    description: 'Ginger tabby',
    street: 'Jl. Kemang Raya',
    area: 'Kemang',
    photoCount: 3,
    wasFed: true,
    seenAt: DateTime(2026, 9, 2, 17, 30),
    gradientColors: const [Color(0xFFE8B58C), Color(0xFFA85C2E)],
  ),
  Sighting(
    id: 's2',
    animal: Species.dog,
    description: 'Scruffy grey terrier mix',
    street: 'Jl. Senopati Raya',
    area: 'Senopati',
    photoCount: 5,
    wasFed: false,
    seenAt: DateTime(2026, 9, 1, 8, 15),
    gradientColors: const [Color(0xFFD8D8D8), Color(0xFF8A8A8A)],
  ),
  Sighting(
    id: 's3',
    animal: Species.cat,
    description: 'Cream longhair',
    street: 'Jl. Cipete Dalam',
    area: 'Cipete',
    photoCount: 2,
    wasFed: true,
    seenAt: DateTime(2026, 8, 30, 19, 45),
    gradientColors: const [Color(0xFFF2E8D5), Color(0xFFC9B78E)],
  ),
  Sighting(
    id: 's4',
    animal: Species.dog,
    description: 'Tan shepherd mix',
    street: 'Jl. Pantai Indah Kapuk Boulevard',
    area: 'PIK',
    photoCount: 6,
    wasFed: false,
    seenAt: DateTime(2026, 8, 29, 6, 50),
    gradientColors: const [Color(0xFFE0C9A6), Color(0xFFB08F5F)],
  ),
  Sighting(
    id: 's5',
    animal: Species.cat,
    description: 'Black shorthair',
    street: 'Jl. Menteng Raya',
    area: 'Menteng',
    photoCount: 4,
    wasFed: false,
    seenAt: DateTime(2026, 8, 28, 21, 10),
    gradientColors: const [Color(0xFF6B6B6B), Color(0xFF2A2A2A)],
  ),
  Sighting(
    id: 's6',
    animal: Species.dog,
    description: 'White fluffy pomeranian',
    street: 'Jl. Jendral Sudirman Kav 52-53',
    area: 'SCBD',
    photoCount: 3,
    wasFed: true,
    seenAt: DateTime(2026, 8, 27, 12, 5),
    gradientColors: const [Color(0xFFF5EFE6), Color(0xFFD9CDBB)],
  ),
];
