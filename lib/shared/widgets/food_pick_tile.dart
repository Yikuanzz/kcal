import 'package:flutter/material.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/food.dart';
import 'food_avatar.dart';

/// 食物选择卡片：记一笔与编辑记录共用的挑选样式。
class FoodPickTile extends StatelessWidget {
  const FoodPickTile({
    super.key,
    required this.food,
    required this.selected,
    required this.onTap,
  });

  final Food food;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF8E7DC) : KcalColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? KcalColors.persimmon : KcalColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FoodAvatar(imageBase64: food.imageBase64, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatAmount(food.kcalPer100g, 0)} kcal / 100 g',
                      style: const TextStyle(color: KcalColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: KcalColors.persimmon),
            ],
          ),
        ),
      ),
    );
  }
}
