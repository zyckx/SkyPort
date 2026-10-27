import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'providers/theme_provider.dart';

const String kCodeFontFamily = 'monospace';

/// System CJK fonts used when the bundled Geist font lacks a glyph.
const List<String> kFontFamilyFallback = [
  'Microsoft YaHei',
  'PingFang SC',
  'Noto Sans CJK SC',
  'Noto Sans SC',
];

extension CodeTextTheme on TextTheme {
  TextStyle get code => bodyMedium!.copyWith(fontFamily: kCodeFontFamily);
}

/// The accent (primary) colour a seed produces for [brightness].
Color buildAccent(Color seed, Brightness brightness) =>
    ColorScheme.fromSeed(seedColor: seed, brightness: brightness).primary;

/// The single source of visual truth: a neutral zinc palette whose primary
/// colour follows the user's accent (manual or system) colour.
ShadThemeData buildShadTheme(Brightness brightness, Color accentSeed) {
  final ShadColorScheme base = brightness == Brightness.light
      ? const ShadZincColorScheme.light()
      : const ShadZincColorScheme.dark();
  final accent = ColorScheme.fromSeed(
    seedColor: accentSeed,
    brightness: brightness,
  );
  return ShadThemeData(
    brightness: brightness,
    colorScheme: base.copyWith(
      primary: accent.primary,
      primaryForeground: accent.onPrimary,
      ring: accent.primary,
    ),
    textTheme: _shadTextTheme(),
  );
}

ShadThemeData getShadLightTheme([
  Color accentSeed = ThemeColorNotifier.defaultColor,
]) => buildShadTheme(Brightness.light, accentSeed);

ShadThemeData getShadDarkTheme([
  Color accentSeed = ThemeColorNotifier.defaultColor,
]) => buildShadTheme(Brightness.dark, accentSeed);

/// Material theme derived from the shadcn theme, so the remaining structural
/// Material widgets (Scaffold, text selection, scrollbars) share its palette.
ThemeData materialThemeFrom(ShadThemeData shad) {
  final colors = shad.colorScheme;
  final brightness = shad.brightness;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
      ).copyWith(
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.secondary,
        onSecondary: colors.secondaryForeground,
        error: colors.destructive,
        onError: colors.destructiveForeground,
        surface: colors.background,
        onSurface: colors.foreground,
        onSurfaceVariant: colors.mutedForeground,
        surfaceContainerLowest: colors.background,
        surfaceContainerLow: colors.card,
        surfaceContainer: colors.muted,
        surfaceContainerHigh: colors.muted,
        surfaceContainerHighest: colors.muted,
        outline: colors.border,
        outlineVariant: colors.border,
      );
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colors.background,
    fontFamily: shad.textTheme.family,
    fontFamilyFallback: kFontFamilyFallback,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.selection,
    ),
  );
}

ThemeData getLightTheme(Color accentSeed) =>
    materialThemeFrom(getShadLightTheme(accentSeed));

ThemeData getDarkTheme(Color accentSeed) =>
    materialThemeFrom(getShadDarkTheme(accentSeed));

ShadTextTheme _shadTextTheme() {
  TextStyle withFallback(TextStyle style) =>
      style.copyWith(fontFamilyFallback: kFontFamilyFallback);
  const family = kDefaultFontFamily;
  return ShadTextTheme.custom(
    h1Large: withFallback(ShadTextDefaultTheme.h1Large(family: family)),
    h1: withFallback(ShadTextDefaultTheme.h1(family: family)),
    h2: withFallback(ShadTextDefaultTheme.h2(family: family)),
    h3: withFallback(ShadTextDefaultTheme.h3(family: family)),
    h4: withFallback(ShadTextDefaultTheme.h4(family: family)),
    p: withFallback(ShadTextDefaultTheme.p(family: family)),
    blockquote: withFallback(ShadTextDefaultTheme.blockquote(family: family)),
    table: withFallback(ShadTextDefaultTheme.table(family: family)),
    list: withFallback(ShadTextDefaultTheme.list(family: family)),
    lead: withFallback(ShadTextDefaultTheme.lead(family: family)),
    large: withFallback(ShadTextDefaultTheme.large(family: family)),
    small: withFallback(ShadTextDefaultTheme.small(family: family)),
    muted: withFallback(ShadTextDefaultTheme.muted(family: family)),
    family: family,
  );
}
