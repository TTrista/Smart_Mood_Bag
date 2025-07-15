import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0C3FC), // 淡紫
      Color(0xFF8EC5FC), // 粉蓝
      Color(0xFFB993D6), // 紫
      Color(0xFF8CA6DB), // 蓝紫
    ],
  );
}

class AppColors {
  static const Color card = Color(0xCCFFFFFF); // 更高透明度白
  static const Color accent = Color(0xFFB993D6); // 主色
  static const Color button = Color(0xFF8CA6DB); // 按钮色
  static const Color text = Color(0xFF333366); // 深紫灰
  static const Color divider = Color(0x338CA6DB); // 分割线淡蓝紫
  static const Color barBg = Color(0xB3FFFFFF); // 半透明白
  static const Color navSelected = Color(0xFF333366); // 底部导航选中字体深色
}

class AppTheme {
  static ThemeData get themeData => ThemeData(
    fontFamily: 'Montserrat',
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.barBg,
      elevation: 2,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: AppColors.card,
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 6,
      shadowColor: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: AppColors.divider,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
      titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.barBg,
      selectedItemColor: AppColors.navSelected,
      unselectedItemColor: AppColors.text,
      elevation: 8,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        color: AppColors.navSelected,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      selectedIconTheme: const IconThemeData(
        color: AppColors.navSelected,
        shadows: [
          Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}
