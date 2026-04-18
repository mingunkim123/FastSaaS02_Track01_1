import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/constants/categories.dart';
import 'package:flutter_app/core/constants/category_icons.dart';
import 'package:flutter_app/shared/providers/transaction_provider.dart';
import 'package:flutter_app/shared/widgets/animated_fade_slide.dart';
import 'package:flutter_app/shared/widgets/glass_card.dart';

// ============================================================
// [거래 기록 화면] record_page.dart
// 수동으로 수입/지출 거래를 입력하는 폼.
// ============================================================
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  String _transactionType = 'expense';
  DateTime _selectedDate = DateTime.now();
  String _amountText = '';
  String? _selectedCategory;
  String _memo = '';
  bool _isLoading = false;

  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  List<String> _getCategories() =>
      _transactionType == 'expense'
          ? Categories.getAllExpenseCategories()
          : Categories.getAllIncomeCategories();

  Color get _accentColor =>
      _transactionType == 'expense' ? AppColors.expense : AppColors.income;

  void _formatAmountInput(String value) {
    final numeric = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numeric.isEmpty) {
      _amountText = '';
      _amountController.clear();
      return;
    }

    try {
      final parsed = double.parse(numeric);
      if (parsed > 999999999) return;
    } catch (_) {
      return;
    }

    _amountText = numeric;
    final formatted = _formatWithCommas(numeric);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithCommas(String value) {
    try {
      if (value.isEmpty) return '';
      if (value.contains('.')) {
        final parts = value.split('.');
        final intPart = int.parse(parts[0]);
        return '${NumberFormat('#,##0').format(intPart)}.${parts[1]}';
      }
      return NumberFormat('#,##0').format(int.parse(value));
    } catch (_) {
      return value;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  String? _validate() {
    if (_amountText.isEmpty) return '금액을 입력해주세요';
    try {
      final amount = double.parse(_amountText);
      if (amount <= 0) return '금액은 0보다 커야 합니다';
    } catch (_) {
      return '유효한 금액을 입력해주세요';
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return '카테고리를 선택해주세요';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _toast(error, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final amount = double.parse(_amountText);
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      await ref.read(addTransactionProvider({
        'transactionType': _transactionType,
        'amount': amount,
        'category': _selectedCategory,
        'date': dateStr,
        if (_memo.isNotEmpty) 'memo': _memo,
      }).future);

      if (!mounted) return;

      setState(() {
        _transactionType = 'expense';
        _selectedDate = DateTime.now();
        _amountText = '';
        _selectedCategory = null;
        _memo = '';
        _amountController.clear();
        _memoController.clear();
        _isLoading = false;
      });

      HapticFeedback.mediumImpact();
      _toast('거래가 저장되었습니다');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast('거래 저장 실패: $e', isError: true);
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.expense : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 기록'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _transactionType = 'expense';
            _selectedDate = DateTime.now();
            _amountText = '';
            _selectedCategory = null;
            _memo = '';
            _amountController.clear();
            _memoController.clear();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedFadeSlide(
                child: _buildTypeToggle(theme),
              ),
              const SizedBox(height: AppSpacing.lg),

              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 80),
                child: _buildDatePicker(theme),
              ),
              const SizedBox(height: AppSpacing.lg),

              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: _buildAmountInput(theme),
              ),
              const SizedBox(height: AppSpacing.lg),

              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 240),
                child: _buildCategoryGrid(categories, theme),
              ),
              const SizedBox(height: AppSpacing.lg),

              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 320),
                child: _buildMemoInput(),
              ),
              const SizedBox(height: AppSpacing.xl),

              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 400),
                child: _buildSubmitButton(theme),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Type toggle ─────────────────────────────────────────────
  Widget _buildTypeToggle(ThemeData theme) {
    return GlassCard(
      accentColor: _accentColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _toggleChip(
              label: '지출',
              active: _transactionType == 'expense',
              color: AppColors.expense,
              icon: FontAwesomeIcons.arrowTrendDown,
              onTap: () => setState(() {
                _transactionType = 'expense';
                _selectedCategory = null;
              }),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _toggleChip(
              label: '수입',
              active: _transactionType == 'income',
              color: AppColors.income,
              icon: FontAwesomeIcons.arrowTrendUp,
              onTap: () => setState(() {
                _transactionType = 'income';
                _selectedCategory = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool active,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: active ? color : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 14,
              color: active ? Colors.white : color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: active ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date picker ─────────────────────────────────────────────
  Widget _buildDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('날짜'),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd (E)', 'ko').format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Amount input ────────────────────────────────────────────
  Widget _buildAmountInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('금액'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: _formatAmountInput,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _accentColor,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: '원',
            suffixStyle: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  // ─── Category grid ───────────────────────────────────────────
  Widget _buildCategoryGrid(List<String> categories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('카테고리'),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.05,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;
            final icon = CategoryIcons.of(category);

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accentColor.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? _accentColor
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? _accentColor
                            : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? _accentColor
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Memo input ──────────────────────────────────────────────
  Widget _buildMemoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('메모'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _memoController,
          onChanged: (value) => setState(() => _memo = value),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '거래에 대한 설명을 입력하세요 (선택사항)',
          ),
        ),
      ],
    );
  }

  // ─── Submit button ───────────────────────────────────────────
  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          elevation: 2,
          shadowColor: _accentColor.withValues(alpha: 0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    _transactionType == 'expense'
                        ? FontAwesomeIcons.circleMinus
                        : FontAwesomeIcons.circlePlus,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _transactionType == 'expense' ? '지출 등록' : '수입 등록',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
