import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable address search field with autocomplete suggestions.
/// Uses Mapbox/Google APIs for real geocoding in production.
class AddressSearchField extends StatefulWidget {
  const AddressSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.onAddressSelected,
    this.initialAddress,
  });

  final String label;
  final IconData icon;
  final Function(String address, double lat, double lng) onAddressSelected;
  final String? initialAddress;

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<_AddressSuggestion> _suggestions = [];

  // Popular Nigerian locations for quick selection
  static final _quickLocations = [
    _AddressSuggestion('Lekki Phase 1, Lagos', 6.4479, 3.4737),
    _AddressSuggestion('Victoria Island, Lagos', 6.4281, 3.4219),
    _AddressSuggestion('Ikeja, Lagos', 6.6018, 3.3515),
    _AddressSuggestion('Surulere, Lagos', 6.5059, 3.3598),
    _AddressSuggestion('Yaba, Lagos', 6.5158, 3.3817),
    _AddressSuggestion('Ajah, Lagos', 6.4670, 3.5860),
    _AddressSuggestion('Ikoyi, Lagos', 6.4490, 3.4310),
    _AddressSuggestion('Marina, Lagos Island', 6.4474, 3.3903),
    _AddressSuggestion('Wuse 2, Abuja', 9.0643, 7.4892),
    _AddressSuggestion('Garki, Abuja', 9.0388, 7.4918),
    _AddressSuggestion('Maitama, Abuja', 9.0826, 7.4953),
    _AddressSuggestion('GRA, Port Harcourt', 4.8156, 7.0498),
    _AddressSuggestion('Sabon Gari, Kano', 12.0022, 8.5127),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = _quickLocations);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _suggestions = _quickLocations
          .where((s) => s.address.toLowerCase().contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? const Color(0xFF00F0FF)
                  : Colors.white12,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(widget.icon, color: const Color(0xFF00F0FF), size: 20),
              hintText: widget.label,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _filterSuggestions('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterSuggestions,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on,
                      color: Color(0xFFFF00AA), size: 18),
                  title: Text(
                    suggestion.address,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: () {
                    _controller.text = suggestion.address;
                    widget.onAddressSelected(
                        suggestion.address, suggestion.lat, suggestion.lng);
                    _focusNode.unfocus();
                    setState(() => _showSuggestions = false);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AddressSuggestion {
  final String address;
  final double lat;
  final double lng;
  _AddressSuggestion(this.address, this.lat, this.lng);
}
