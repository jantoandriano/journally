import 'package:flutter/material.dart';

import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

class MockJournalRepository implements JournalRepository {
  static final List<JournalEntry> _entries = [
    JournalEntry(
      id: '1',
      placeName: 'Kopi Manyar',
      neighborhood: 'Kemang',
      city: 'Jakarta',
      orderItems: const ['Iced Gula Aren Latte', 'Butter Croissant'],
      photoCount: 4,
      gradientColors: [const Color(0xFFE7C9A5), const Color(0xFFB8763F)],
    ),
    JournalEntry(
      id: '2',
      placeName: 'Sarah Coffee Bar',
      neighborhood: 'SCBD',
      city: 'Jakarta',
      orderItems: const ['Flat White', 'Avocado Toast', 'Cold Brew'],
      photoCount: 6,
      gradientColors: [const Color(0xFFD8C7E8), const Color(0xFF8C6FAE)],
    ),
    JournalEntry(
      id: '3',
      placeName: 'Tuku Coffee',
      neighborhood: 'Senopati',
      city: 'Jakarta',
      orderItems: const ['Es Kopi Susu'],
      photoCount: 2,
      gradientColors: [const Color(0xFFC9E0D8), const Color(0xFF5F9782)],
    ),
    JournalEntry(
      id: '4',
      placeName: 'Anomali Coffee',
      neighborhood: 'Menteng',
      city: 'Jakarta',
      orderItems: const ['Cappuccino', 'Banana Bread'],
      photoCount: 3,
      gradientColors: [const Color(0xFFF0D8B0), const Color(0xFFC98A4B)],
    ),
    JournalEntry(
      id: '5',
      placeName: 'Common Grounds',
      neighborhood: 'PIK',
      city: 'Jakarta',
      orderItems: const [
        'Matcha Latte',
        'Cinnamon Roll',
        'Americano',
        'Bagel',
      ],
      photoCount: 8,
      gradientColors: [const Color(0xFFCFE0EE), const Color(0xFF6B92B8)],
    ),
    JournalEntry(
      id: '6',
      placeName: 'Filosofi Kopi',
      neighborhood: 'Kemang',
      city: 'Jakarta',
      orderItems: const ['Vietnam Drip', 'Pisang Goreng'],
      photoCount: 5,
      gradientColors: [const Color(0xFFE3D3C3), const Color(0xFF9C7A5B)],
    ),
  ];

  @override
  Future<List<JournalEntry>> fetchEntries() async {
    return _entries;
  }
}
