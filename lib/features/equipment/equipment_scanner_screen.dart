import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/features/equipment/equipment_list_screen.dart';

class EquipmentScannerScreen extends StatefulWidget {
  const EquipmentScannerScreen({super.key});

  @override
  State<EquipmentScannerScreen> createState() => _EquipmentScannerScreenState();
}

class _EquipmentScannerScreenState extends State<EquipmentScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate finding a barcode after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isScanning) {
        _simulateSuccessfulScan();
      }
    });
  }

  void _simulateSuccessfulScan() {
    setState(() {
      _isScanning = false;
      _scannerController.stop();
    });
    
    // Auto-navigate to equipment after showing success
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EquipmentListScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera background
      body: Stack(
        children: [
          // Simulated Camera Viewfinder
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.backgroundTertiary.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                  radius: 1.5,
                ),
              ),
            ),
          ),
          
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanning ? AppTheme.primaryGreen.withValues(alpha: 0.5) : AppTheme.successGreen,
                  width: 2,
                ),
                borderRadius: AppTheme.radiusLg,
              ),
              child: Stack(
                children: [
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _scannerController,
                      builder: (context, child) {
                        return Positioned(
                          top: _scannerController.value * 240,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (!_isScanning)
                    Center(
                      child: Icon(
                        LucideIcons.checkCircle2,
                        color: AppTheme.successGreen,
                        size: 80,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'סריקת ציוד רפואי',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
            ),
          ),

          // Footer Text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isScanning ? 'כוון את המצלמה לברקוד צה"לי (צ\')' : 'הסריקה הושלמה בהצלחה',
                    style: TextStyle(
                      color: _isScanning ? Colors.white : AppTheme.successGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isScanning) ...[
                    const SizedBox(height: AppTheme.spacing24),
                    SizedBox(
                      width: 200,
                      child: HopalButton(
                        label: 'הזנה ידנית במקום',
                        variant: HopalButtonVariant.secondary,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const EquipmentListScreen()),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
