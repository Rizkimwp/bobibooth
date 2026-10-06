import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_view_model.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';

class ShareScreenView
    extends ScreenViewBase<ShareScreenViewModel, ShareScreenController> {
  const ShareScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Observer(
      builder: (_) {
        if (viewModel.isTemplateEditing) {
          return _templateEditor;
        }

        return _finalResult;
      },
    );
  }

  // ==============================================================
  // TEMPLATE EDITOR
  // ==============================================================

  Widget get _templateEditor {
    final template = viewModel.selectedTemplate;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0B0B0D),
        ),

        // Background glow.
        Positioned(
          top: -180,
          left: -120,
          child: IgnorePointer(
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F7A63).withAlpha(35),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              _editorHeader,

              const SizedBox(height: 8),

              Text(
                template?.name ?? 'Customize your photo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Klik foto untuk memasukkannya ke slot berikutnya',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TEMPLATE PREVIEW
              // ==================================================
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 35),

                    Expanded(flex: 6, child: _templatePreview),

                    const SizedBox(width: 30),

                    Expanded(flex: 4, child: _photoPicker),

                    const SizedBox(width: 35),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _editorBottomBar,

              const SizedBox(height: 22),
            ],
          ),
        ),
      ],
    );
  }

  Widget get _editorHeader {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 25, 35, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F7A63),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CREATE PHOTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Text(
            'BOBI BOOTH',
            style: TextStyle(
              color: Colors.white.withAlpha(110),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TEMPLATE PREVIEW
  // ==============================================================

  Widget get _templatePreview {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 35,
              spreadRadius: 4,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RepaintBoundary(
            child: PhotoCollage(
              key: controller.collageKey,
              aspectRatio: _collageAspectRatio,
              padding: _collagePadding,
            ),
          ),
        ),
      ),
    );
  }

  double get _collageAspectRatio {
    final template = viewModel.selectedTemplate;

    if (template == null || template.height == 0) {
      return 1.0;
    }

    return template.width / template.height;
  }

  double get _collagePadding {
    return 0.0;
  }

 

  Widget get _photoPicker {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.images,
                size: 19,
                color: Color(0xFF79C9A4),
              ),
              const SizedBox(width: 9),
              const Text(
                'Your Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _slotCounter,
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Pilih foto satu per satu untuk mengisi template.',
            style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: viewModel.availablePhotos.isEmpty
                ? _emptyPhotos
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: viewModel.availablePhotos.length,
                    itemBuilder: (context, index) {
                      final photoIndex = viewModel.availablePhotos[index];

                      return _photoCard(photoIndex);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget get _slotCounter {
    final current = viewModel.assignedPhotoCount;

    final total = viewModel.templatePhotoCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: current >= total
            ? const Color(0xFF1F7A63)
            : Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget get _emptyPhotos {
    return Center(
      child: Text(
        'Tidak ada foto yang tersedia.',
        style: TextStyle(color: Colors.white.withAlpha(120)),
      ),
    );
  }

  // ==============================================================
  // PHOTO CARD
  // ==============================================================

  Widget _photoCard(int photoIndex) {
    final photos = getIt<PhotosManager>().photos;

    if (photoIndex < 0 || photoIndex >= photos.length) {
      return const SizedBox.shrink();
    }

    final PhotoCapture photo = photos[photoIndex];

    final assigned = viewModel.isPhotoAssigned(photoIndex);

    int assignedNumber = 0;

    if (assigned) {
      assignedNumber = getIt<PhotosManager>().chosen.indexOf(photoIndex) + 1;
    }

    return GestureDetector(
      onTap: assigned
          ? null
          : () {
              viewModel.assignPhoto(photoIndex);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            width: assigned ? 2.5 : 1,
            color: assigned
                ? const Color(0xFF1F7A63)
                : Colors.white.withAlpha(25),
          ),
          boxShadow: assigned
              ? [
                  BoxShadow(
                    color: const Color(0xFF1F7A63).withAlpha(60),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(photo.data, fit: BoxFit.cover),

            if (assigned) Container(color: Colors.black.withAlpha(90)),

            if (assigned)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F7A63),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$assignedNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            if (!assigned)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.black.withAlpha(0),
                  child: AnimatedOpacity(
                    opacity: 0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F7A63),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // EDITOR BOTTOM BAR
  // ==============================================================

  Widget get _editorBottomBar {
    final ready = viewModel.allSlotsFilled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          Button(
            onPressed: viewModel.resetTemplateAssignments,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              ),
              backgroundColor: WidgetStateProperty.all(
                Colors.white.withAlpha(12),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withAlpha(20)),
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.rotateCcw, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Button(
            onPressed: controller.onClickPrev,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              ),
              backgroundColor: WidgetStateProperty.all(
                Colors.white.withAlpha(12),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withAlpha(20)),
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.arrowLeft, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Button(
            onPressed: ready ? controller.onGenerateTemplate : null,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white.withAlpha(10);
                }

                return const Color(0xFF1F7A63);
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  ready
                      ? 'Generate Photo'
                      : 'Pilih ${viewModel.templatePhotoCount - viewModel.assignedPhotoCount} foto lagi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // FINAL RESULT
  // ==============================================================

  Widget get _finalResult {
    final image = ImageWithLoaderFallback.memory(
      viewModel.outputImage,
      fit: BoxFit.contain,
      onImageDecoded: viewModel.onImageDecoded,
    );

    final preview = Observer(
      builder: (_) {
        if (viewModel.imageSize == null) {
          return image;
        }

        return AspectRatio(
          aspectRatio: viewModel.imageSize!.aspectRatio,
          child: image,
        );
      },
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0B0B0D)),

        Positioned(
          top: -180,
          left: -120,
          child: IgnorePointer(
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F7A63).withAlpha(35),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 28, 40, 10),
                child: Row(
                  children: [
                    _statusBadge,

                    const Spacer(),

                    Text(
                      'BOBI BOOTH',
                      style: TextStyle(
                        color: Colors.white.withAlpha(130),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Column(
                  children: [
                    Text(
                      'Your photo is ready!',
                      textAlign: TextAlign.center,
                      style: theme.titleTheme.style?.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take a look before you continue',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                      maxHeight: 600,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: preview,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _modernNavigationButton(
                            icon: LucideIcons.stepBack,
                            text: viewModel.backText,
                            onPressed: controller.onClickPrev,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: _modernNavigationButton(
                            icon: LucideIcons.stepForward,
                            text: localizations.genericDoneButton,
                            onPressed: controller.onClickNext,
                            primary: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (viewModel.showGetQrButton) ...[
                          Expanded(
                            child: _modernActionButton(
                              icon: LucideIcons.scanQrCode,
                              text: localizations.photoDetailsScreenGetQrButton,
                              onPressed: controller.onClickGetQR,
                            ),
                          ),
                          const SizedBox(width: 12,
                          ),
                        ],

                        Expanded(
                          child: Observer(
                            builder: (_) {
                              return _modernActionButton(
                                icon: LucideIcons.printer,
                                text: viewModel.printText,
                                onPressed: viewModel.printEnabled
                                    ? controller.onClickPrint
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (viewModel.displayConfetti) ..._confettiStack,
      ],
    );
  }

  // ==============================================================
  // STATUS
  // ==============================================================

  Widget get _statusBadge {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1F7A63),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'PHOTO READY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // NAVIGATION BUTTON
  // ==============================================================

  Widget _modernNavigationButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white.withAlpha(8);
          }

          if (primary) {
            return const Color(0xFF1F7A63);
          }

          return Colors.white.withAlpha(14);
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: primary
                  ? Colors.white.withAlpha(0)
                  : Colors.white.withAlpha(25),
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!primary) ...[
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (primary) ...[
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: Colors.white),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // ACTION BUTTON
  // ==============================================================

  Widget _modernActionButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        ),
        backgroundColor: WidgetStateProperty.all(Colors.white.withAlpha(10)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withAlpha(20)),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white.withAlpha(210)),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CONFETTI
  // ==============================================================

  List<Widget> get _confettiStack {
    return [
      Align(alignment: Alignment.bottomLeft, child: _confetti(-0.25 * pi, 45)),
      Align(alignment: Alignment.bottomLeft, child: _confetti(-0.325 * pi, 42)),
      Align(alignment: Alignment.bottomLeft, child: _confetti(-0.4 * pi, 30)),
      Align(alignment: Alignment.bottomRight, child: _confetti(-0.75 * pi, 45)),
      Align(
        alignment: Alignment.bottomRight,
        child: _confetti(-0.675 * pi, 42),
      ),
      Align(alignment: Alignment.bottomRight, child: _confetti(-0.6 * pi, 30)),
    ];
  }

  Widget _confetti(double direction, double force) {
    return ConfettiWidget(
      confettiController: viewModel.confettiController,
      blastDirection: direction,
      maximumSize: const Size(60, 30),
      minimumSize: const Size(40, 20),
      colors: viewModel.getColors(),
      minBlastForce: force,
      maxBlastForce: force * 2,
      particleDrag: 0.01,
      emissionFrequency: 0.6,
      numberOfParticles: 10,
      gravity: 0.3,
      shouldLoop: false,
      displayTarget: false,
    );
  }
}
