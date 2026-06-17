import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Add Category Dialog - Small dialog to add new category
class AddCategoryDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> result)? onAdd;
  
  const AddCategoryDialog({super.key, this.onAdd});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category_rounded;
  String _categoryName = '';

  final List<IconData> _availableIcons = [
    Icons.category_rounded,
    Icons.shopping_cart_rounded,
    Icons.local_cafe_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.fitness_center_rounded,
    Icons.local_hospital_rounded,
    Icons.music_note_rounded,
    Icons.movie_rounded,
    Icons.local_gas_station_rounded,
    Icons.phone_android_rounded,
    Icons.computer_rounded,
    Icons.child_care_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_grocery_store_rounded,
    Icons.restaurant_menu_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    final name = _categoryName.trim();
    debugPrint('=== _onAddPressed called, name: $name ===');
    if (name.isNotEmpty) {
      HapticFeedback.mediumImpact();
      final result = {
        'name': name,
        'icon': _selectedIcon,
      };
      debugPrint('=== Returning result: $result ===');
      
      // Use callback if provided, otherwise use Navigator
      if (widget.onAdd != null) {
        widget.onAdd!(result);
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        Navigator.of(context, rootNavigator: true).pop(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canAdd = _categoryName.trim().isNotEmpty;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Category',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D5DB8),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Name Field
            Text(
              'Category Name',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _categoryName = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'e.g., Groceries, Gym, Travel',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selection
            Text(
              'Choose Icon',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = icon);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D5DB8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0D5DB8)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0D5DB8),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Preview
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5DB8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedIcon,
                      color: const Color(0xFF0D5DB8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _categoryName.isEmpty ? 'Preview' : _categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D5DB8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canAdd ? _onAddPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5DB8),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add Category',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canAdd ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the Add Category Dialog
Future<Map<String, dynamic>?> showAddCategoryDialog(BuildContext context) async {
  debugPrint('=== showAddCategoryDialog called ===');
  
  Map<String, dynamic>? result;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      debugPrint('=== Dialog builder called ===');
      return AddCategoryDialog(
        onAdd: (data) {
          debugPrint('=== onAdd callback: $data ===');
          result = data;
        },
      );
    },
  );
  
  debugPrint('=== Final result: $result ===');
  return result;
}


