import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/lottie_animation_wrapper.dart';
import 'package:momento_booth/views/components/animations/repeating_indicator.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view_model.dart';

class StartScreenView
    extends ScreenViewBase<StartScreenViewModel, StartScreenController> {
  const StartScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return LottieAnimationWrapper(
      animationSettings: viewModel.introScreenLottieAnimations,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================================
          // BACKGROUND
          // ==========================================================

          _background,

          // ==========================================================
          // GRADIENT OVERLAY
          // ==========================================================
          _backgroundOverlay,

          // ==========================================================
          // MAIN CONTENT
          // ==========================================================
          _mainContent,

          // ==========================================================
          // TOUCH INDICATOR
          // ==========================================================
          if (viewModel.showTouchIndicator)
            Center(
              child: IgnorePointer(
                child: RepeatingIndicator(
                  lottieAsset:
                      'assets/animations/Animation - 1764508028194.json',
                  cycleDuration: const Duration(seconds: 5),
                  size: 220,
                ),
              ),
            ),

          // ==========================================================
          // SETTINGS
          // ==========================================================
          Observer(
            builder: (context) {
              if (!viewModel.showSettingsButton) {
                return const SizedBox.shrink();
              }

              return Positioned(top: 24, right: 24, child: _settingsButton);
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BACKGROUND
  // ================================================================

  Widget get _background {
    return Image.asset(
      'assets/bitmap/background.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // ================================================================
  // BACKGROUND OVERLAY
  // ================================================================

  Widget get _backgroundOverlay {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(100),
            Colors.black.withAlpha(40),
            Colors.black.withAlpha(110),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  // ================================================================
  // MAIN CONTENT
  // ================================================================

  Widget get _mainContent {
    return SafeArea(
      child: Column(
        children: [
          // ==========================================================
          // TOP LOGO
          // ==========================================================

          const SizedBox(height: 40),

          _logo,

          const Spacer(),

          // ==========================================================
          // TITLE
          // ==========================================================
          _title,

          const SizedBox(height: 14),

          // ==========================================================
          // SUBTITLE
          // ==========================================================
          _subtitle,

          const SizedBox(height: 38),

          // ==========================================================
          // START BUTTON
          // ==========================================================
          _startButton,

          const SizedBox(height: 20),
          // ==========================================================
          // Galery BUTTON
          // ==========================================================
          _galleryButton,

          const SizedBox(height: 20),
          // ==========================================================
          // HINT
          // ==========================================================
          _hint,

          const Spacer(),

          // ==========================================================
          // BOTTOM INFO
          // ==========================================================
          _bottomInfo,

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ================================================================
  // LOGO
  // ================================================================

  Widget get _logo {
    return SizedBox(
      width: 260,
      height: 90,
      child: SvgPicture.asset(
        'assets/svg/logo.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }

  // ================================================================
  // TITLE
  // ================================================================

  Widget get _title {
    return Observer(
      builder: (context) {
        final texts = viewModel.startTexts;

        if (texts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Text(
          texts.first,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            height: 1.05,
          ),
        );
      },
    );
  }
  // ================================================================
  // SUBTITLE
  // ================================================================

  Widget get _subtitle {
    return Text(
      'Create your memories in just a few clicks.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withAlpha(205),
        fontSize: 19,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
    );
  }

  // ================================================================
  // START BUTTON
  // ================================================================

  Widget get _startButton {
    return _StartButton(onPressed: controller.onPressedContinue);
  }

  // ================================================================
  // GALLERY BUTTON
  // ================================================================

  Widget get _galleryButton {
    return _GalleryButton(onPressed: controller.onPressedGallery);
  }
  // ================================================================
  // HINT
  // ================================================================

  Widget get _hint {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.hand, size: 18, color: Colors.white.withAlpha(170)),
        const SizedBox(width: 8),
        Text(
          'Tap to start',
          style: TextStyle(
            color: Colors.white.withAlpha(175),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SETTINGS BUTTON
  // ================================================================

  Widget get _settingsButton {
    return _GlassButton(
      icon: LucideIcons.settings,
      onPressed: controller.onPressedOpenSettings,
    );
  }

  // ================================================================
  // BOTTOM INFO
  // ================================================================

  Widget get _bottomInfo {
    return Text(
      'Your moment. Your memory.',
      style: TextStyle(
        color: Colors.white.withAlpha(130),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ====================================================================
// GALLERY BUTTON
// ====================================================================

class _GalleryButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GalleryButton({required this.onPressed});

  @override
  State<_GalleryButton> createState() => _GalleryButtonState();
}

class _GalleryButtonState extends State<_GalleryButton> {
  bool _hovered = false;
  bool _pressed = false;

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
              ? 0.96
              : _hovered
              ? 1.03
              : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 220,
            height: 58,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withAlpha(45)
                  : Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withAlpha(_hovered ? 100 : 55),
                width: 1,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: Colors.black.withAlpha(45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.images,
                  color: Colors.white.withAlpha(_hovered ? 255 : 210),
                  size: 20,
                ),

                const SizedBox(width: 10),

                Text(
                  'Gallery',
                  style: TextStyle(
                    color: Colors.white.withAlpha(_hovered ? 255 : 220),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ====================================================================
// START BUTTON
// ====================================================================

class _StartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _StartButton({required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hovered = false;
  bool _pressed = false;

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
              ? 0.96
              : _hovered
              ? 1.03
              : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 300,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: _hovered ? Colors.white : Colors.white.withAlpha(235),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_hovered ? 100 : 65),
                  blurRadius: _hovered ? 35 : 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: Colors.white,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 14),

                const Text(
                  'Start Photo',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(width: 10),

                Icon(
                  LucideIcons.arrowRight,
                  color: const Color(0xFF111827),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// GLASS BUTTON
// ====================================================================

// ====================================================================
// GLASS BUTTON
// ====================================================================

class _GlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassButton({required this.icon, required this.onPressed});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;
  bool _pressed = false;

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
              ? 0.94
              : _hovered
              ? 1.05
              : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withAlpha(55)
                  : Colors.black.withAlpha(45),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withAlpha(_hovered ? 120 : 65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_hovered ? 70 : 40),
                  blurRadius: _hovered ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white.withAlpha(_hovered ? 255 : 210),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
