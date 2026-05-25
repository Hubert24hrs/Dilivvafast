import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProposePriceSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final double recommendedPrice;

  const ProposePriceSheet({
    super.key,
    required this.onSave,
    this.recommendedPrice = 1500.0, // Default recommended price
  });

  @override
  State<ProposePriceSheet> createState() => _ProposePriceSheetState();
}

class _ProposePriceSheetState extends State<ProposePriceSheet> {
  bool _receiverPays = false;
  String _paymentMethod = 'Cash'; // Cash or Transfer
  late double _currentPrice;
  late double _minPrice; // Recommended - 200 (max reduction)
  late double _maxPrice; // Recommended + 1000 (max addition)
  
  @override
  void initState() {
    super.initState();
    _currentPrice = widget.recommendedPrice;
    _minPrice = widget.recommendedPrice - 200; // Max reduction is 200
    _maxPrice = widget.recommendedPrice + 1000; // Max addition is 1000
  }

  void _adjustPrice(double amount) {
    setState(() {
      final newPrice = _currentPrice + amount;
      // Can't go below minPrice (recommended - 200)
      // Can't go above maxPrice (recommended + 1000)
      if (newPrice >= _minPrice && newPrice <= _maxPrice) {
        _currentPrice = newPrice;
      } else if (newPrice < _minPrice) {
        _currentPrice = _minPrice;
      } else if (newPrice > _maxPrice) {
        _currentPrice = _maxPrice;
      }
    });
  }

  void _handleSave() {
    final data = {
      'price': _currentPrice,
      'recommendedPrice': widget.recommendedPrice,
      'paymentMethod': _paymentMethod,
      'receiverPays': _receiverPays,
    };
    widget.onSave(data);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canDecrease = _currentPrice > _minPrice;
    final canIncrease = _currentPrice < _maxPrice;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Propose your price',
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
              const SizedBox(height: 20),

              // Recommended Price Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline, 
                      color: AppTheme.primaryColor, 
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended: ₦${widget.recommendedPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Price Display with +/- Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Decrease Button
                  _buildAdjustButton(
                    icon: Icons.remove,
                    onPressed: canDecrease ? () => _adjustPrice(-100) : null,
                    isEnabled: canDecrease,
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Current Price Display
                  Text(
                    '₦${_currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Increase Button
                  _buildAdjustButton(
                    icon: Icons.add,
                    onPressed: canIncrease ? () => _adjustPrice(100) : null,
                    isEnabled: canIncrease,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Payment Method
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.money, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _paymentMethod,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      color: AppTheme.surfaceColor,
                      onSelected: (value) => setState(() => _paymentMethod = value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'Transfer', child: Text('Transfer', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Receiver Pays Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receiver settles fee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'To courier, when package arrives',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: _receiverPays,
                    onChanged: (value) => setState(() => _receiverPays = value),
                    activeTrackColor: AppTheme.primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm ₦${_currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled 
            ? AppTheme.primaryColor.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled 
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : Colors.white10,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppTheme.primaryColor : Colors.white24,
          size: 28,
        ),
      ),
    );
  }
}

