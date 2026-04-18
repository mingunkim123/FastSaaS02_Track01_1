import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ============================================================
// [카테고리 아이콘 매핑] category_icons.dart
// 한국어 카테고리명 → FontAwesome 아이콘.
// RecordPage 카테고리 그리드와 기타 UI에서 재사용.
// ============================================================
class CategoryIcons {
  CategoryIcons._();

  static IconData of(String? category) {
    switch (category) {
      // Expense
      case '식비':
        return FontAwesomeIcons.bowlFood;
      case '교통':
        return FontAwesomeIcons.bus;
      case '쇼핑':
        return FontAwesomeIcons.bagShopping;
      case '의료':
        return FontAwesomeIcons.briefcaseMedical;
      case '문화여가':
        return FontAwesomeIcons.film;
      case '월세':
        return FontAwesomeIcons.house;
      // Income
      case '월급':
        return FontAwesomeIcons.moneyBillWave;
      case '부업':
        return FontAwesomeIcons.briefcase;
      case '용돈':
        return FontAwesomeIcons.wallet;
      // Default
      case '기타':
      default:
        return FontAwesomeIcons.ellipsis;
    }
  }
}
