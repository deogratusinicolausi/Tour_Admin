import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/deal_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';

class AddEditDealScreen extends StatefulWidget {
  final DealModel? deal;
  const AddEditDealScreen({super.key, this.deal});

  @override
  State<AddEditDealScreen> createState() => _AddEditDealScreenState();
}

class _AddEditDealScreenState extends State<AddEditDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _cloudinary = CloudinaryService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _itemNameController = TextEditingController();

  String _currency = 'USD';
  String _itemType = 'tour';
  String _itemId = '';
  String _imageUrl = '';
  int _discount = 0;
  String _status = 'active';
  bool _featured = false;
  bool _isLoading = false;
  bool _isUploading = false;

  DateTime? _startDate;
  DateTime? _endDate;

  bool get isEditing => widget.deal != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final d = widget.deal!;
    _titleController.text = d.title;
    _descriptionController.text = d.description;
    _originalPriceController.text = d.originalPrice.toString();
    _salePriceController.text = d.salePrice.toString();
    _itemNameController.text = d.itemName;
    _currency = d.currency;
    _itemType = d.itemType;
    _itemId = d.itemId;
    _imageUrl = d.imageUrl;
    _discount = d.discount;
    _status = d.status;
    _featured = d.featured;
    _startDate = d.startDate;
    _endDate = d.endDate;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _isUploading = true);

      String? url;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinary.uploadImageBytes(bytes, folder: 'turiva/deals');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path), folder: 'turiva/deals');
      }

      setState(() {
        if (url != null) _imageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  void _calculateDiscount() {
    final original = double.tryParse(_originalPriceController.text) ?? 0;
    final sale = double.tryParse(_salePriceController.text) ?? 0;
    if (original > 0 && sale > 0 && sale < original) {
      setState(() {
        _discount = (((original - sale) / original) * 100).round();
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_upload_image')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final deal = DealModel(
      id: widget.deal?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      discount: _discount,
      originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
      salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
      currency: _currency,
      imageUrl: _imageUrl,
      itemType: _itemType,
      itemId: _itemId,
      itemName: _itemNameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      featured: _featured,
      createdAt: widget.deal?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) success = await _service.updateDeal(deal);
    else {
      final id = await _service.addDeal(deal);
      success = id != null;
    }

    setState(() => _isLoading = false);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? context.tr('updated_success') : context.tr('added_success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _salePriceController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? context.tr('edit_deal') : context.tr('add_deal')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(context.tr('deal_image'), width),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: height * 0.25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageUrl.isEmpty ? Colors.grey.shade300 : AppColors.primary,
                      width: 2,
                    ),
                    image: _imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(_imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: width * 0.15, color: Colors.grey.shade400),
                      SizedBox(height: height * 0.01),
                        Text(context.tr('tap_to_upload'),
                          style: TextStyle(color: context.textSecondary)),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.025),

              _title(context.tr('deal_information'), width),
              SizedBox(height: height * 0.01),
              _field(context, _titleController, context.tr('deal_title'), Icons.title,
                  validator: (v) => v!.isEmpty ? context.tr('required') : null),
              SizedBox(height: height * 0.015),
              _field(context, _itemNameController, context.tr('item_name'), Icons.card_giftcard,
                  hint: 'e.g. Serengeti Safari'),
              SizedBox(height: height * 0.015),
              _field(context, _descriptionController, context.tr('description'), Icons.description,
                  maxLines: 3),
              SizedBox(height: height * 0.025),

              _title(context.tr('pricing'), width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _field(context, _originalPriceController, context.tr('original_price'),
                        Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateDiscount(),
                        validator: (v) => v!.isEmpty ? context.tr('required') : null),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _field(context, _salePriceController, context.tr('sale_price'),
                        Icons.local_offer,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateDiscount(),
                        validator: (v) => v!.isEmpty ? context.tr('required') : null),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: height * 0.02),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['USD', 'TZS', 'EUR', 'GBP']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: height * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(context.tr('discount').toUpperCase(),
                              style: TextStyle(
                                  fontSize: width * 0.025,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text('$_discount%',
                              style: TextStyle(
                                  fontSize: width * 0.05,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              _title(context.tr('deal_duration'), width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(isStart: true),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('start_date'),
                                style: TextStyle(
                                    fontSize: width * 0.028,
                                    color: context.textSecondary)),
                            SizedBox(height: height * 0.005),
                            Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : context.tr('select_date'),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _startDate != null
                                      ? context.textPrimary
                                      : context.textSecondary.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(isStart: false),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('end_date'),
                                style: TextStyle(
                                    fontSize: width * 0.028,
                                    color: context.textSecondary)),
                            SizedBox(height: height * 0.005),
                            Text(
                              _endDate != null
                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                  : context.tr('select_date'),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _endDate != null
                                      ? context.textPrimary
                                      : context.textSecondary.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              _title(context.tr('settings'), width),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                    color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: Text('⭐ ' + context.tr('featured'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                  value: _featured,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() => _featured = v),
                ),
              ),
              SizedBox(height: height * 0.015),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                    color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: ['active', 'inactive'].map((s) {
                    final isSelected = _status == s;
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: Container(
                        margin: EdgeInsets.only(right: width * 0.03),
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05, vertical: height * 0.01),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (s == 'active' ? Colors.green : Colors.grey)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: height * 0.03),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isEditing ? context.tr('update_deal').toUpperCase() : context.tr('add_deal').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String t, double w) => Text(
    t,
    style: TextStyle(
        fontSize: w * 0.04,
        fontWeight: FontWeight.bold,
        color: context.textPrimary),
  );

  Widget _field(
      BuildContext context,
      TextEditingController c,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
        String? hint,
        Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: c,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: context.textSecondary),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}