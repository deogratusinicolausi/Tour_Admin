import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import 'package:provider/provider.dart';

class AddEditCouponScreen extends StatefulWidget {
  final CouponModel? coupon;

  const AddEditCouponScreen({super.key, this.coupon});

  @override
  State<AddEditCouponScreen> createState() => _AddEditCouponScreenState();
}

class _AddEditCouponScreenState extends State<AddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CouponService();

  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();
  final _termsController = TextEditingController();

  String _discountType = 'percentage';
  String _applicableTo = 'all';
  String _currency = 'USD';
  int _perUserLimit = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _applicableOptions = [
    'all',
    'hotel',
    'tour',
    'beach',
    'mountain',
    'culture',
    'food',
    'deal',
  ];

  final List<String> _currencies = ['USD', 'TZS', 'EUR', 'GBP'];

  bool get isEditing => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final c = widget.coupon!;
    _codeController.text = c.code;
    _titleController.text = c.title;
    _descriptionController.text = c.description;
    _discountController.text = c.discountValue.toString();
    _minAmountController.text = c.minAmount.toString();
    _maxDiscountController.text = c.maxDiscount.toString();
    _usageLimitController.text = c.usageLimit.toString();
    _termsController.text = c.termsAndConditions;
    _discountType = c.discountType;
    _applicableTo = c.applicableTo;
    _currency = c.currency;
    _perUserLimit = c.perUserLimit;
    _startDate = c.startDate;
    _endDate = c.endDate;
    _isActive = c.isActive;
  }

  void _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    String code = 'TURIVA';
    for (int i = 0; i < 6; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    setState(() => _codeController.text = code);
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_codeController.text.trim().isEmpty) {
      _showError('Coupon code is required');
      return;
    }

    setState(() => _isLoading = true);

    final coupon = CouponModel(
      id: widget.coupon?.id ?? '',
      code: _codeController.text.trim().toUpperCase(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      discountType: _discountType,
      discountValue: double.tryParse(_discountController.text) ?? 0,
      minAmount: double.tryParse(_minAmountController.text) ?? 0,
      maxDiscount: double.tryParse(_maxDiscountController.text) ?? 0,
      currency: _currency,
      applicableTo: _applicableTo,
      usageLimit: int.tryParse(_usageLimitController.text) ?? 0,
      usedCount: widget.coupon?.usedCount ?? 0,
      perUserLimit: _perUserLimit,
      usedBy: widget.coupon?.usedBy ?? [],
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
      termsAndConditions: _termsController.text.trim(),
      createdAt: widget.coupon?.createdAt ?? DateTime.now(),
    );

    try {
      bool success;
      if (isEditing) {
        success = await _service.updateCoupon(coupon);
      } else {
        final id = await _service.addCoupon(coupon);
        success = id != null;
      }

      setState(() => _isLoading = false);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(isEditing
                ? 'coupon_updated'
                : 'coupon_created')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(context.tr(isEditing ? 'edit_coupon' : 'create_coupon')),
        backgroundColor: context.cardBg,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CODE
              _sectionTitle(context.tr('coupon_code'), width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'TURIVA20',
                        filled: true,
                        fillColor: context.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.textSecondary.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  GestureDetector(
                    onTap: _generateCode,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.045),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome,
                          color: Colors.black, size: width * 0.06),
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.025),

              // TITLE
              _sectionTitle(context.tr('title'), width),
              SizedBox(height: height * 0.01),
              _buildField(context, _titleController, 'e.g. Summer Sale 20% OFF',
                  Icons.title,
                  validator: (v) =>
                  v!.isEmpty ? context.tr('title_required') : null),

              SizedBox(height: height * 0.02),

              // DESCRIPTION
              _sectionTitle(context.tr('description'), width),
              SizedBox(height: height * 0.01),
              _buildField(
                  context, _descriptionController, 'Coupon details...', Icons.description,
                  maxLines: 3),

              SizedBox(height: height * 0.025),

              // DISCOUNT TYPE
              _sectionTitle('💰 Discount Type', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  _typeButton(context, 'percentage', '%', context.tr('percentage'), width),
                  SizedBox(width: width * 0.03),
                  _typeButton(context, 'fixed', '\$', context.tr('fixed_amount'), width),
                ],
              ),

              SizedBox(height: height * 0.02),

              // DISCOUNT VALUE
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context.tr('discount_value'), width),
                        SizedBox(height: height * 0.01),
                        _buildField(
                          context, _discountController,
                          _discountType == 'percentage' ? '20' : '50',
                          _discountType == 'percentage'
                              ? Icons.percent
                              : Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                          v!.isEmpty ? context.tr('required') : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  if (_discountType == 'fixed')
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context.tr('currency'), width),
                          SizedBox(height: height * 0.01),
                          _buildDropdown(context, _currency, _currencies, (v) {
                            setState(() => _currency = v!);
                          }),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: height * 0.02),

              // MIN AMOUNT + MAX DISCOUNT
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context.tr('min_purchase'), width),
                        SizedBox(height: height * 0.01),
                        _buildField(
                          context, _minAmountController,
                          context.tr('min_amount_hint'),
                          Icons.shopping_cart,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context.tr('max_discount'), width),
                        SizedBox(height: height * 0.01),
                        _buildField(
                          context, _maxDiscountController,
                          context.tr('no_limit'),
                          Icons.trending_down,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.025),

              // APPLICABLE TO
              _sectionTitle(context.tr('applicable_to'), width),
              SizedBox(height: height * 0.01),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _applicableOptions.map((option) {
                  final isSelected = _applicableTo == option;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _applicableTo = option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.textSecondary.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        option == 'all'
                            ? '🌍 ${context.tr('all_items')}'
                            : option.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: height * 0.025),

              // VALIDITY DATES
              _sectionTitle(context.tr('validity_period'), width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(isStart: true),
                      child: _dateBox(
                        context,
                        context.tr('start_date'),
                        _startDate,
                        Icons.calendar_today,
                        width,
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(isStart: false),
                      child: _dateBox(
                        context,
                        context.tr('end_date'),
                        _endDate,
                        Icons.event,
                        width,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.025),

              // USAGE LIMITS
              _sectionTitle(context.tr('usage_limits'), width),
              SizedBox(height: height * 0.01),
              _buildField(
                context,
                _usageLimitController,
                context.tr('unlimited'),
                Icons.people,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(context.tr('per_user_limit'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038)),
                    ),
                    DropdownButton<int>(
                      value: _perUserLimit,
                      underline: const SizedBox(),
                      items: [1, 2, 3, 5, 0]
                          .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v == 0 ? context.tr('unlimited') : '$v'),
                      ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _perUserLimit = v);
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.025),

              // TERMS
              _sectionTitle(context.tr('terms_and_conditions'), width),
              SizedBox(height: height * 0.01),
              _buildField(context, _termsController, 'Optional terms...', Icons.rule,
                  maxLines: 3),

              SizedBox(height: height * 0.025),

              // ACTIVE
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(context.tr('active'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Coupon will be available for use'),
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),

              SizedBox(height: height * 0.03),

              // SAVE
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    context.tr(isEditing ? 'update_coupon' : 'create_coupon').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.038,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildField(
      BuildContext context,
      TextEditingController controller,
      String hint,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      BuildContext context, String value, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.textSecondary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _typeButton(
      BuildContext context, String value, String icon, String label, double width) {
    final isSelected = _discountType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = value),
        child: Container(
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
              isSelected ? AppColors.primary : context.textSecondary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: width * 0.08,
                  color: isSelected ? Colors.white : context.textPrimary,
                ),
              ),
              SizedBox(height: width * 0.01),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.03,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBox(
      BuildContext context, String label, DateTime? date, IconData icon, double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: date != null ? AppColors.primary : context.textSecondary.withOpacity(0.2),
          width: date != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: width * 0.04, color: AppColors.primary),
              SizedBox(width: width * 0.01),
              Text(label,
                  style: TextStyle(
                      color: context.textSecondary,
                      fontSize: width * 0.026)),
            ],
          ),
          SizedBox(height: width * 0.01),
          Text(
            date != null
                ? DateFormat('dd MMM yyyy').format(date)
                : context.tr('select_date'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: width * 0.035,
              color: date != null
                  ? context.textPrimary
                  : context.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}