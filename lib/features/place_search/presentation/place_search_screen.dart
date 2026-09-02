import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/place_search_result.dart';
import 'providers/place_search_providers.dart';
import 'widgets/back_button.dart';
import 'widgets/place_result_tile.dart';

enum _SearchState { idle, loading, loaded, empty, error }

class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  _SearchState _state = _SearchState.idle;
  List<PlaceSearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _state = _SearchState.idle;
        _results = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    setState(() => _state = _SearchState.loading);
    try {
      final results = await ref.read(placeSearchRepositoryProvider).search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _state = results.isEmpty ? _SearchState.empty : _SearchState.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _SearchState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlaceSearchBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Text(
                    'Add a place',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: colors.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          color: colors.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'Search for a cafe or place',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 14.5,
                            color: colors.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_state == _SearchState.loading) ...[
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    switch (_state) {
      case _SearchState.idle:
        return Center(
          child: Text(
            'Keep typing to search for a place',
            style: GoogleFonts.manrope(fontSize: 13.5, color: colors.outline),
          ),
        );
      case _SearchState.loading:
        return const SizedBox.shrink();
      case _SearchState.empty:
        return Center(
          child: Text(
            'No places found',
            style: GoogleFonts.manrope(fontSize: 13.5, color: colors.outline),
          ),
        );
      case _SearchState.error:
        return Center(
          child: Text(
            "Couldn't search right now.",
            style: GoogleFonts.manrope(fontSize: 13.5, color: colors.onSurfaceVariant),
          ),
        );
      case _SearchState.loaded:
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final result = _results[index];
            return PlaceResultTile(
              result: result,
              onTap: () => Navigator.pop(context, result),
            );
          },
        );
    }
  }
}

