import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteEntrySheet extends StatefulWidget {
  final Function(String) onSave;

  const RouteEntrySheet({
    super.key,
    required this.onSave,
  });

  @override
  State<RouteEntrySheet> createState() => _RouteEntrySheetState();
}

class _RouteEntrySheetState extends State<RouteEntrySheet> {
  final _toController = TextEditingController();

  void _handleSave() {
    if (_toController.text.isNotEmpty) {
      widget.onSave(_toController.text);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance the close button
                const Text(
                  'Enter your route',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location (Read-only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Current Location',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // To Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _toController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'To',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _handleSave(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Choose on map
                TextButton.icon(
                  onPressed: () async {
                    final result = await context.push('/location-picker');
                    if (result != null && result is String) {
                      _toController.text = result;
                    }
                  },
                  icon: const Icon(Icons.map_outlined, color: AppTheme.secondaryColor),
                  label: const Text(
                    'Choose on map',
                    style: TextStyle(color: AppTheme.secondaryColor, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),

                const SizedBox(height: 24),
                
                // Done Button (Optional, but good for UX)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Set Destination'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
