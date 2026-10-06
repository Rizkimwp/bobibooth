import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/fading_text_swticher.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view_model.dart';

class NavigationScreenView
    extends
        ScreenViewBase<NavigationScreenViewModel, NavigationScreenController> {
  const NavigationScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  static const Color _green = Color(0xFF176B4D);
  static const Color _greenDark = Color(0xFF0E4F39);
  static const Color _greenLight = Color(0xFFEAF7F1);

  @override
  Widget get body {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, _green, Color(0xFF23805D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 38),

            // ========================================================
            // HEADER
            // ========================================================
            _header,

            const SizedBox(height: 42),

            // ========================================================
            // MENU
            // ========================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: _menuGrid,
              ),
            ),

            // ========================================================
            // BOTTOM
            // ========================================================
            _bottomRow,

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget get _header {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          localizations.navigationScreenTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Choose how you want to capture your moment',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(190),
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // MENU GRID
  // ================================================================
  Widget get _menuGrid {
    final List<Widget> buttons = [];

    if (viewModel.enableSingleCapture && viewModel.enableCollageCapture) {
      buttons
        ..add(
          _menuButton(
            icon: LucideIcons.image,
            title: localizations.chooseCaptureModeScreenSinglePictureButton,
            subtitle: 'Take a single photo',
            onPressed: controller.onClickSinglePhoto,
          ),
        )
        ..add(
          _menuButton(
            icon: LucideIcons.layoutGrid,
            title: localizations.chooseCaptureModeScreenCollageButton,
            subtitle: 'Create a photo collage',
            onPressed: controller.onClickCollage,
        ),
        );
    } else {
      buttons.add(
        _menuButton(
          icon: viewModel.enableSingleCapture
              ? LucideIcons.image
              : LucideIcons.layoutGrid,
          title: viewModel.enableSingleCapture
              ? localizations.chooseCaptureModeScreenSinglePictureButton
              : localizations.chooseCaptureModeScreenCollageButton,
          subtitle: viewModel.enableSingleCapture
              ? 'Take a single photo'
              : 'Create a photo collage',
          onPressed: controller.onClickPhoto,
      ),
    );
  }

    if (viewModel.showGallery) {
      buttons.add(
        _menuButton(
          icon: LucideIcons.images,
          title: localizations.startScreenGalleryButton,
          subtitle: 'View your captured memories',
          onPressed: controller.onClickGallery,
        ),
      );
    }

    if (viewModel.showGallery) {
      buttons.add(
        _menuButton(
          icon: LucideIcons.layoutTemplate,
          title: 'Templates',
          subtitle: 'Manage your photo templates',
          onPressed: controller.onClickTemplate,
      ),
    );
  }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount;
        double spacing;
        double childAspectRatio;

        if (width < 650) {
          // ============================================
          // MOBILE / WINDOW KECIL
          // ============================================
          crossAxisCount = 1;
          spacing = 14;
          childAspectRatio = 2.5;
        } else if (width < 950) {
          // ============================================
          // TABLET / WINDOW MEDIUM
          // ============================================
          crossAxisCount = 2;
          spacing = 18;
          childAspectRatio = 1.7;
        } else {
          // ============================================
          // DESKTOP / WINDOW BESAR
          // ============================================
          crossAxisCount = 3;
          spacing = 24;
          childAspectRatio = 1.5;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buttons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                return buttons[index];
              },
            ),
          ),
        );
      },
    );
  }
  // ================================================================
  // MENU BUTTON
  // ================================================================

  Widget _menuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return _ModernMenuButton(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onPressed: onPressed,
    );
  }

  // ================================================================
  // BOTTOM ROW
  // ================================================================

  Widget get _bottomRow {
    return Observer(
      builder: (context) {
        if (viewModel.projectAvailableLanguages.length == 1) {
          return const SizedBox.shrink();
        }

        return _changeLanguageButton;
      },
    );
  }

  // ================================================================
  // LANGUAGE
  // ================================================================

  Widget get _changeLanguageButton {
    return _LanguageButton(
      onPressed: controller.onClickLanguage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.languages, size: 22, color: _green),
          const SizedBox(width: 10),
          FadingTextSwitcher(
            texts: viewModel.changeLanguageTexts,
            style: const TextStyle(
              color: _green,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            displayDuration: const Duration(seconds: 3),
            fadeDuration: const Duration(milliseconds: 500),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// MODERN MENU BUTTON
// ====================================================================

class _ModernMenuButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _ModernMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  State<_ModernMenuButton> createState() => _ModernMenuButtonState();
}

class _ModernMenuButtonState extends State<_ModernMenuButton> {
  bool _hovered = false;
  bool _pressed = false;

  static const Color _green = Color(0xFF176B4D);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed
              ? 0.97
              : _hovered
              ? 1.02
              : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _hovered ? Colors.white : Colors.white.withAlpha(180),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_hovered ? 65 : 35),
                  blurRadius: _hovered ? 30 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 28),
              child: Row(
                children: [
                  // --------------------------------------------------
                  // ICON
                  // --------------------------------------------------

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: _hovered ? _green : const Color(0xFFEAF7F1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 42,
                      color: _hovered ? Colors.white : _green,
                    ),
                  ),

                  const SizedBox(width: 24),

                  // --------------------------------------------------
                  // TEXT
                  // --------------------------------------------------
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          widget.title,
                          maxLines: 1,
                          minFontSize: 18,
                          style: const TextStyle(
                            color: Color(0xFF14251E),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 7),

                        AutoSizeText(
                          widget.subtitle,
                          maxLines: 1,
                          minFontSize: 12,
                          style: TextStyle(
                            color: Colors.black.withAlpha(120),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 18),

                  // --------------------------------------------------
                  // ARROW
                  // --------------------------------------------------
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _hovered ? _green : const Color(0xFFEAF7F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 19,
                      color: _hovered ? Colors.white : _green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// LANGUAGE BUTTON
// ====================================================================

class _LanguageButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _LanguageButton({required this.onPressed, required this.child});

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton> {
  bool _hovered = false;

  static const Color _green = Color(0xFF176B4D);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_hovered ? 50 : 25),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
