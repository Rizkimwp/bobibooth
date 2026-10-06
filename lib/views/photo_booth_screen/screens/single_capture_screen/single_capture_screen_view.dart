import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen_view_model.dart';

class SingleCaptureScreenView
    extends
        ScreenViewBase<
          SingleCaptureScreenViewModel,
          SingleCaptureScreenController
        > {
  const SingleCaptureScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // ==========================================================
        // COLLAGE RENDER
        // ==========================================================

        PhotoCollage(
          key: viewModel.collageKey,
          forceLayout: 1,
          aspectRatio: 1 / viewModel.collageAspectRatio,
          padding: viewModel.collagePadding,
          decodeCallback: viewModel.collageReady,
          isVisible: false,
        ),

        // ==========================================================
        // MAIN CONTENT
        // ==========================================================
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _getReadyText,

            const SizedBox(height: 20),

            Flexible(
              child: Container(
                padding: const EdgeInsets.all(40.0),
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 600,
                ),
                child: Observer(
                  builder: (_) {
                    if (!viewModel.showCounter) {
                      return const SizedBox.shrink();
                    }

                    return CaptureCounter(
                      onCounterFinished: viewModel.onCounterFinished,
                      counterStart: viewModel.counterStart,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ========================================================
            // TAKE PHOTO BUTTON
            // ========================================================
            Observer(
              builder: (_) {
                if (viewModel.showCounter) {
                  return const SizedBox.shrink();
                }

                if (viewModel.showSpinner) {
                  return const SizedBox.shrink();
                }

                return _takePhotoButton;
              },
            ),
          ],
        ),

        // ==========================================================
        // BACK BUTTON
        // ==========================================================
        Positioned(
          top: 24,
          left: 24,
          child: Button(
            onPressed: () {
              router.go(NavigationScreen.defaultRoute);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.back, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ==========================================================
        // LOADING
        // ==========================================================
        Observer(
          builder: (_) {
            if (viewModel.showSpinner) {
              return Center(
                child: LoadingDialog.cameraDownload(
                  title: localizations.captureScreenLoadingPhoto,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),

        // ==========================================================
        // FLASH
        // ==========================================================
        _flashAnimation,
      ],
    );
  }
  // ================================================================
  // GET READY TEXT
  // ================================================================

  Widget get _getReadyText {
    return Observer(
      builder: (_) {
        if (!viewModel.showCounter) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ready?',
                style: theme.titleTheme.style?.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Press the button when you are ready',
                style: TextStyle(
                  color: Colors.white.withAlpha(190),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 160,
          child: AnimatedTextKit(
            pause: Duration(
              milliseconds: viewModel.counterStart >= 3 ? 1000 : 0,
            ),
            isRepeatingAnimation: false,
            animatedTexts: [
              RotateAnimatedText(
                localizations.captureScreenGetReady,
                textStyle: theme.titleTheme.style?.copyWith(
                  color: Colors.white,
                ),
                duration: const Duration(milliseconds: 1000),
              ),
              RotateAnimatedText(
                localizations.captureScreenLookAtCamera,
                textStyle: theme.titleTheme.style?.copyWith(
                  color: Colors.white,
                ),
                duration: const Duration(milliseconds: 1000),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // TAKE PHOTO BUTTON
  // ================================================================

  Widget get _takePhotoButton {
    return Button(
      onPressed: controller.onPressedTakePhoto,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.camera, size: 24),

            const SizedBox(width: 12),

            Text(
              'Take Photo',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FLASH
  // ================================================================

  Widget get _flashAnimation {
    return Observer(
      builder: (_) {
        return IgnorePointer(
          ignoring: !viewModel.showFlash,
          child: AnimatedOpacity(
            opacity: viewModel.opacity,
            duration: viewModel.flashAnimationDuration,
            curve: viewModel.flashAnimationCurve,
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        );
      },
    );
  }
}
