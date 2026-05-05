import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import 'glass_card.dart';

class SearchSheet extends StatefulWidget {
  final void Function(CitySearchResult) onSelect;
  final VoidCallback onUseCurrent;

  const SearchSheet({
    super.key,
    required this.onSelect,
    required this.onUseCurrent,
  });

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _ctrl = TextEditingController();
  List<CitySearchResult> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _results = []; });
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await WeatherService.searchCities(q);
      if (mounted) setState(() { _results = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        onChanged: _search,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Current location option
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7AB8FF).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.my_location, color: Color(0xFF7AB8FF), size: 20),
              ),
              title: const Text('Use current location',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Detect your precise area',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                widget.onUseCurrent();
              },
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            // Results
            if (_loading)
              const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(
                  color: Color(0xFF7AB8FF), strokeWidth: 2))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final r = _results[i];
                    final subtitle = [r.admin1, r.country].where((s) => s != null && s.isNotEmpty).join(', ');
                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.location_city, color: Colors.white.withOpacity(0.7), size: 18),
                      ),
                      title: Text(r.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: subtitle.isNotEmpty ? Text(subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)) : null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(r);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showSearchSheet(BuildContext context, {
  required void Function(CitySearchResult) onSelect,
  required VoidCallback onUseCurrent,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SearchSheet(onSelect: onSelect, onUseCurrent: onUseCurrent),
  );
}
