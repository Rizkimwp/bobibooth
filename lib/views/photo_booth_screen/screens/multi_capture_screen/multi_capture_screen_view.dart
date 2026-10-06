import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/live_view.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen.dart';

class MultiCaptureScreenView
    extends
        ScreenViewBase<
          MultiCaptureScreenViewModel,
          MultiCaptureScreenController
        > {
  const MultiCaptureScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ============================================================
        // HIDDEN COLLAGE
        // ============================================================

        if (viewModel.enablePhotoCollageWidget)
          PhotoCollage(
            key: viewModel.collageKey,
            forceLayout: viewModel.maxPhotos,
            aspectRatio: 1 / viewModel.collageAspectRatio,
            padding: viewModel.collagePadding,
            decodeCallback: viewModel.collageReady,
            isVisible: false,
          ),

        // ============================================================
        // MAIN CONTENT
        // ============================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========================================================
            // LEFT PHOTO PANEL
            // ========================================================

            SizedBox(width: 230, child: _photoColumn),

            // ========================================================
            // CAMERA
            // ========================================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: const Color(0xFF111111),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ==================================================
                        // LIVE VIEW
                        // ==================================================

                        _liveViewWithCounter,

                        // ==================================================
                        // CAPTURE LOADING
                        // ==================================================
                        Observer(
                          builder: (_) {
                            if (!viewModel.showSpinner) {
                              return const SizedBox();
                            }

                            return Container(
                              color: const Color(0x88000000),
                              child: Center(
                                child: LoadingDialog.cameraDownload(
                                  title:
                                      localizations.captureScreenLoadingPhoto,
                                ),
                              ),
                            );
                          },
                        ),

                        // ==================================================
                        // TOP STATUS
                        // ==================================================
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: _topStatus,
                        ),

                        // ================================================
                        // Back Button
                        // ===============================================
                        Positioned(top: 20, right: 20, child: _backButton),

                        // ==================================================
                        // BUTTON
                        // ==================================================
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 24,
                          child: _captureButtons,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ============================================================
        // FLASH
        // ============================================================
        _flashAnimation,
      ],
    );
  }

  // ============================================================
  // LEFT PHOTO PANEL
  // ============================================================

  Widget get _photoColumn {
    final photosManager = getIt<PhotosManager>();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FluentIcons.camera,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // ==================================================
                    // JUMLAH FOTO
                    // ==================================================
                    Observer(
                      builder: (_) {
                        final count = photosManager.photos.length;

                        return Text(
                          '$count of ${viewModel.maxPhotos} captured',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ========================================================
          // PROGRESS
          // ========================================================
          Observer(
            builder: (_) {
              final count = photosManager.photos.length;
              final max = viewModel.maxPhotos;

              final progress = max == 0 ? 0.0 : (count / max).clamp(0.0, 1.0);

              return ProgressBar(value: progress * 100, strokeWidth: 6);
            },
          ),

          const SizedBox(height: 18),

          // ========================================================
          // PHOTOS
          // ========================================================
          Expanded(
            child: Observer(
              builder: (_) {
                // PENTING:
                // Observer membaca ObservableList secara langsung.
                final photos = photosManager.photos;
                print('PHOTOS UI => ${photos.length}');
                final maxPhotos = viewModel.maxPhotos;

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: maxPhotos,
                  separatorBuilder: (_, __) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (_, index) {
                    // Foto sudah tersedia
                    if (index < photos.length) {
                      return SizedBox(
                        height: 150,
                        child: _capturedPhoto(index),
                      );
                    }

                    // Foto belum tersedia
                    return SizedBox(
                      height: 150,
                      child: _photoPlaceholder(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAPTURED PHOTO
  // ============================================================

  Widget _capturedPhoto(int index) {
    final photosManager = getIt<PhotosManager>();

    return Observer(
      builder: (_) {
        if (index >= photosManager.photos.length) {
          return _photoPlaceholder(index);
        }

        final photo = photosManager.photos[index];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E3E3)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Color(0x12000000),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageWithLoaderFallback.memory(
                photo.data,
                applyRotateFlipCrop: true,
              ),

              // ======================================================
              // NUMBER
              // ======================================================
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xDD111111),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ======================================================
              // CHECK
              // ======================================================
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F7A63),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FluentIcons.check_mark,
                    color: Color(0xFFFFFFFF),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // ========
  // Back Button

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget get _backButton {
    return FilledButton(
      onPressed: () {
        router.go(NavigationScreen.defaultRoute);
      },
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        backgroundColor: WidgetStatePropertyAll(Color(0xCC111111)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.back, size: 16),
          SizedBox(width: 8),
          Text(
            'BACK',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO PLACEHOLDER
  // ============================================================

  Widget _photoPlaceholder(int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                FluentIcons.camera,
                color: Color(0xFF999999),
                size: 19,
              ),
            ),
          ),

          Positioned(
            left: 12,
            bottom: 10,
            child: Text(
              'Photo ${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE VIEW + COUNTDOWN
  // ============================================================

  Widget get _liveViewWithCounter {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ==========================================================
        // LIVE VIEW
        // ==========================================================

        const LiveView(fit: BoxFit.contain),

        // ==========================================================
        // CAMERA ERROR
        // ==========================================================
        Observer(
          builder: (_) {
            final cameraUnavailable = viewModel.cameraUnavailable;

            if (!cameraUnavailable) {
              return const SizedBox();
            }

            return _cameraUnavailableOverlay;
          },
        ),

        // ==========================================================
        // COUNTDOWN
        // ==========================================================
        _countdownOverlay,
      ],
    );
  }

  Widget get _countdownOverlay {
    return Observer(
      builder: (_) {
        final showCounter = viewModel.showCounter;
        final cameraUnavailable = viewModel.cameraUnavailable;

        if (!showCounter || cameraUnavailable) {
          return const SizedBox();
        }

        return Container(
          color: const Color.fromARGB(51, 228, 195, 195),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getReadyText,

              const SizedBox(height: 12),

              Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 40,
                      spreadRadius: 5,
                      color: Color(0x55000000),
                    ),
                  ],
                ),
                child: CaptureCounter(
                  onCounterFinished: viewModel.onCounterFinished,
                  counterStart: viewModel.counterStart,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // ============================================================
  // CAMERA UNAVAILABLE
  // ============================================================

  Widget get _cameraUnavailableOverlay {
    return Container(
      color: const Color.fromARGB(237, 227, 243, 3),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FluentIcons.device_off,
                  color: Color(0xFFFFFFFF),
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Camera Tidak Tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                viewModel.cameraErrorMessage ??
                    'Kamera belum siap atau tidak terhubung.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // FilledButton(
              //   onPressed: viewModel.retryCamera,
              //   child: const Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(
              //         FluentIcons.refresh,
              //         size: 16,
              //       ),
              //       SizedBox(width: 8),
              //       Text(
              //         'COBA LAGI',
              //         style: TextStyle(
              //           fontWeight: FontWeight.w700,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP STATUS
  // ============================================================

  Widget get _topStatus {
    return Observer(
      builder: (_) {
        String text;
        IconData icon;

        if (viewModel.cameraUnavailable) {
          text = 'Camera unavailable';
          icon = FluentIcons.device_off;
        } else if (viewModel.allPhotosCaptured) {
          text = 'All photos captured';
          icon = FluentIcons.check_mark;
        } else if (viewModel.isCapturing) {
          text = 'Get ready...';
          icon = FluentIcons.camera;
        } else {
          text =
              'Ready for photo '
              '${viewModel.currentPhotoNumber}';
          icon = FluentIcons.camera;
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color.fromARGB(204, 183, 255, 0),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: const Color(0xFFFFFFFF)),

                const SizedBox(width: 8),

                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =======================================================
  // Get Back
  // =======================================================

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget get _captureButtons {
    return Observer(
      builder: (_) {
        final allPhotosCaptured = viewModel.allPhotosCaptured;

        final isCapturing = viewModel.isCapturing;

        final cameraUnavailable = viewModel.cameraUnavailable;

        // ========================================================
        // CAMERA ERROR
        // ========================================================

        if (cameraUnavailable) {
          return const SizedBox();
        }

        // ========================================================
        // DONE
        // ========================================================

        if (allPhotosCaptured) {
          return Center(
            child: _modernButton(
              icon: FluentIcons.check_mark,
              label: 'DONE',
              onPressed: isCapturing ? null : viewModel.navigateAfterCapture,
            ),
          );
        }

        // ========================================================
        // TAKE PHOTO
        // ========================================================

        return Center(
          child: _modernButton(
            icon: FluentIcons.camera,
            label: isCapturing ? 'GET READY...' : 'TAKE PHOTO',
            onPressed: isCapturing ? null : viewModel.triggerCapture,
          ),
        );
      },
    );
  }

  // ============================================================
  // MODERN BUTTON
  // ============================================================

  Widget _modernButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;

    return FilledButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0x22FFFFFF)
                  : const Color(0x11000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18),
          ),

          const SizedBox(width: 10),

          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // READY TEXT
  // ============================================================

  Widget get _getReadyText {
    return SizedBox(
      height: 55,
      child: AnimatedTextKit(
        pause: Duration(milliseconds: viewModel.counterStart >= 3 ? 1000 : 0),
        isRepeatingAnimation: false,
        animatedTexts: [
          RotateAnimatedText(
            localizations.multiCaptureScreenGetReady,
            textStyle: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  offset: Offset(0, 2),
                  color: Color(0x99000000),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 1000),
          ),

          RotateAnimatedText(
            localizations.multiCaptureScreenLookAtCamera,
            textStyle: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  offset: Offset(0, 2),
                  color: Color(0x99000000),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 1000),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FLASH
  // ============================================================

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
