import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dilivvafast/core/services/location_helper.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Reusable address search field with autocomplete suggestions.
/// Uses Mapbox forward geocoding with fallback to hardcoded locations.
class AddressSearchField extends StatefulWidget {
  const AddressSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.onAddressSelected,
    this.initialAddress,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Function(String address, double lat, double lng) onAddressSelected;
  final String? initialAddress;
  final Widget? trailing;

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  bool _isSearching = false;
  List<GeocodedAddress> _suggestions = [];
  Timer? _debounce;
  final _locationHelper = LocationHelper();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Show default suggestions when field gets focus
      _searchAddresses(_controller.text);
      setState(() => _showSuggestions = true);
    } else {
      // Delay hiding to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showSuggestions = false);
      });
    }
  }

  void _onTextChanged(String query) {
    // Debounce the search to avoid excessive API calls
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchAddresses(query);
    });
  }

  Future<void> _searchAddresses(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _locationHelper.searchAddresses(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSuggestion(GeocodedAddress suggestion) {
    _controller.text = suggestion.address;
    widget.onAddressSelected(
      suggestion.address,
      suggestion.lat,
      suggestion.lng,
    );
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        Container(
          decoration: BoxDecoration(
            color: context.palette.surfaceRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? context.palette.brand
                  : context.palette.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      widget.icon,
                      color: context.palette.brand,
                      size: 20,
                    ),
                    hintText: widget.label,
                    hintStyle: TextStyle(color: context.palette.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: context.palette.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _controller.clear();
                              _onTextChanged('');
                            },
                          )
                        : (_isSearching
                              ? Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.palette.brand,
                                    ),
                                  ),
                                )
                              : null),
                  ),
                  onChanged: _onTextChanged,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.trailing!,
                ),
            ],
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: context.palette.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.palette.border),
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
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: context.palette.border),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_on,
                    color: context.palette.brand,
                    size: 18,
                  ),
                  title: Text(
                    suggestion.address,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}
