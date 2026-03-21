import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../theme/colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';

/// A Bottom Sheet modal screen designed for rapidly logging a newly executed trade.
/// Keeps the design minimalistic to reduce input friction.
class TradeEntryScreen extends StatefulWidget {
  final Trade? existingTrade;
  const TradeEntryScreen({super.key, this.existingTrade});


  @override
  State<TradeEntryScreen> createState() => _TradeEntryScreenState();
}

class _TradeEntryScreenState extends State<TradeEntryScreen> {
  // Global key to manage and validate the form state
  final _formKey = GlobalKey<FormState>();

  // Text input controllers to capture the user's data
  final _symbolController = TextEditingController();
  final _entryController = TextEditingController();
  final _exitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _lessonsController = TextEditingController();

  // State variable for the selected date and time
  DateTime _selectedDate = DateTime.now();

  // State variable to determine if the trade is Long or Short
  String _tradeType = 'Long';

  // State variable for attached chart screenshot
  File? _pickedImage;
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrade != null) {
      final t = widget.existingTrade!;
      _symbolController.text = t.symbol;
      _entryController.text = t.entryPrice.toString();
      _exitController.text = t.exitPrice.toString();
      _quantityController.text = t.quantity.toString();
      _notesController.text = t.notes;
      _lessonsController.text = t.lessons;
      _selectedDate = t.date;
      _tradeType = t.type;
      _existingImagePath = t.imagePath;
      if (t.imagePath != null) {
        _pickedImage = File(t.imagePath!);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  Future<String?> _saveImagePermanently(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'trade_chart_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String permanentPath = path.join(directory.path, fileName);
      
      // Copy the file to the app's permanent storage
      final File savedImage = await imageFile.copy(permanentPath);
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Opens a DatePicker followed by a TimePicker to combine into _selectedDate
  Future<void> _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accent,
                onPrimary: Colors.black,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _symbolController.dispose();
    _entryController.dispose();
    _exitController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _lessonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Padding handles the bottom keyboard inset to prevent UI covering
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small visual drag handle indicator at top
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.existingTrade != null ? 'Edit Trade' : 'Log Trade',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // --- Trade Type Toggle Buttons (Long / Short) ---
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Long',
                      _tradeType == 'Long',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeButton(
                      'Short',
                      _tradeType == 'Short',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Form Input Fields ---
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Ticker symbol
                    _buildTextField(
                      'Symbol / Ticker',
                      null,
                      'e.g. AAPL, EUR/USD',
                      controller: _symbolController,
                    ),
                    const SizedBox(height: 16),
                    // Entry / Exit Prices side-by-side
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Entry Price',
                            Icons.login,
                            '0.00',
                            controller: _entryController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Exit Price',
                            Icons.logout,
                            '0.00',
                            controller: _exitController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quantity and Date split row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Quantity',
                            Icons.numbers,
                            '0',
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDateAndTime(context),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date & Time',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                DateFormat('MMM d, h:mm a').format(_selectedDate),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Optional Notes & Tags field
                    _buildTextField(
                      'Why did you take this trade?',
                      Icons.psychology_outlined,
                      'Describe your entry reasoning...',
                      maxLines: 2,
                      isRequired: false,
                      controller: _notesController,
                    ),
                    const SizedBox(height: 16),
                    // What did you learn
                    _buildTextField(
                      'What did you learn from this trade?',
                      Icons.lightbulb_outline_rounded,
                      'Lessons, mistakes, or key takeaways...',
                      maxLines: 2,
                      isRequired: false,
                      controller: _lessonsController,
                    ),
                    const SizedBox(height: 24),

                    // --- Image Attachment Section ---
                    const Text(
                      'CHART SCREENSHOT (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surfaceHighlight,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _pickedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _pickedImage!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => setState(() => _pickedImage = null),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, 
                                      color: AppColors.accent.withValues(alpha: 0.5), 
                                      size: 32),
                                  const SizedBox(height: 8),
                                  const Text('Attach Trade Setup',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Save Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate form before closing
                          if (_formKey.currentState!.validate()) {
                            // Extract data and safely parse numbers
                            final double entry =
                                double.tryParse(_entryController.text) ?? 0.0;
                            final double exit =
                                double.tryParse(_exitController.text) ?? 0.0;
                            final double quantity =
                                double.tryParse(_quantityController.text) ??
                                0.0;

                            // Save image if picked
                            String? finalImagePath = _existingImagePath;
                            if (_pickedImage != null && _pickedImage?.path != _existingImagePath) {
                              finalImagePath = await _saveImagePermanently(_pickedImage!);
                            } else if (_pickedImage == null) {
                              finalImagePath = null;
                            }

                            // Instantiate or update the Trade model
                            final incomingTrade = Trade(
                              id: widget.existingTrade?.id, // Keep same ID if editing
                              symbol: _symbolController.text.toUpperCase(),
                              type: _tradeType,
                              entryPrice: entry,
                              exitPrice: exit,
                              quantity: quantity,
                              date: _selectedDate,
                              notes: _notesController.text,
                              lessons: _lessonsController.text,
                              imagePath: finalImagePath,
                            );

                            // Send to provider
                            final provider = Provider.of<TradeProvider>(context, listen: false);
                            if (widget.existingTrade != null) {
                              provider.updateTrade(incomingTrade);
                            } else {
                              provider.addTrade(incomingTrade);
                            }

                            Navigator.pop(context); // Close the bottom sheet
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.existingTrade != null ? 'Update Trade' : 'Save Trade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build standardized text input fields.
  Widget _buildTextField(
    String label,
    IconData? icon,
    String hint, {
    int maxLines = 1,
    bool isRequired = true,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary) : null,
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Highlight border when actively interacting with the field
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      // Basic validation ensures field is not empty if required
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  /// Helper to build the selectable Long/Short toggle buttons.
  Widget _buildTypeButton(String type, bool isSelected, Color activeColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tradeType = type; // Update selected trade direction
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surfaceHighlight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
