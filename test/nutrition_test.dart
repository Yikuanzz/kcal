import 'package:flutter_test/flutter_test.dart';
import 'package:kcal/core/nutrition.dart';

void main() {
  test('千焦按 4.184 换算成千卡', () {
    expect(kcalFromKj(418.4), closeTo(100, 0.0001));
    expect(kcalFromKj(485), closeTo(115.918, 0.001));
  });

  test('按食用克数缩放每百克营养', () {
    final scaled = scaleFood(
      grams: 200,
      kjPer100g: 485,
      carbPer100g: 25.9,
      proteinPer100g: 2.6,
      fatPer100g: 0.3,
    );
    expect(scaled.kcal, closeTo(231.837, 0.01));
    expect(scaled.carb, closeTo(51.8, 0.001));
    expect(scaled.protein, closeTo(5.2, 0.001));
    expect(scaled.fat, closeTo(0.6, 0.001));
  });

  test('对照指标时区分超出、刚好与尚余', () {
    expect(
      progressCaption(
        const IntakeProgress(consumed: 2180, target: 2000),
        unit: 'kcal',
      ),
      '超出 180 kcal',
    );
    expect(
      progressCaption(
        const IntakeProgress(consumed: 2000, target: 2000),
        unit: 'kcal',
      ),
      '刚好达到指标',
    );
    expect(
      progressCaption(
        const IntakeProgress(consumed: 760, target: 2000),
        unit: 'kcal',
      ),
      '尚余 1240 kcal',
    );
    expect(
      progressCaption(const IntakeProgress(consumed: 10, target: 0), unit: 'g'),
      '尚未设置指标',
    );
  });

  test('日期键用本地年月日', () {
    expect(dayKey(DateTime(2026, 10, 20, 23, 30)), '2026-10-20');
    expect(relativeDayTitle(DateTime(2026, 10, 20), DateTime(2026, 10, 20, 8)), '今日');
    expect(relativeDayTitle(DateTime(2026, 10, 19), DateTime(2026, 10, 20)), '昨日');
  });
}
