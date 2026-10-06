import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';

part 'single_capture_screen_view_model.g.dart';

class SingleCaptureScreenViewModel = SingleCaptureScreenViewModelBase
    with _$SingleCaptureScreenViewModel;

abstract class SingleCaptureScreenViewModelBase extends ScreenViewModelBase
    with Store {
  late final PhotoCaptureMethod capturer;

  bool flashComplete = false;
  bool captureComplete = false;

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;

  double get collageAspectRatio =>
      getIt<SettingsManager>().settings.collageAspectRatio;

  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  // ============================================================
  // STATE
  // ============================================================

  /// Awalnya false karena capture tidak boleh langsung dimulai.
  @observable
  bool showCounter = false;

  /// Menandakan user sudah menekan tombol Take Photo.
  @observable
  bool captureStarted = false;

  @observable
  bool showFlash = false;

  @observable
  bool showSpinner = false;

  // ============================================================
  // COMPUTED
  // ============================================================

  @computed
  double get opacity => showFlash ? 1.0 : 0.0;

  @computed
  Curve get flashAnimationCurve => Curves.easeOutQuart;

  @computed
  Duration get flashAnimationDuration =>
      showFlash ? flashStartDuration : flashEndDuration;

  // ============================================================
  // COLLAGE
  // ============================================================

  /// Global key for controlling the slider widget.
  final GlobalKey<PhotoCollageState> collageKey =
      GlobalKey<PhotoCollageState>();

  final Completer<void> completer = Completer<void>();

  void collageReady() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  // ============================================================
  // START CAPTURE
  // ============================================================

  /// Dipanggil ketika user menekan tombol "Take Photo".
  ///
  /// Sebelumnya proses capture dijalankan langsung dari constructor.
  /// Sekarang proses capture baru dimulai setelah user menekan tombol.
  void startCapture() {
    if (captureStarted) return;

    captureStarted = true;
    showCounter = true;

    getIt<PhotosManager>().initiateDelayedPhotoCapture(onCaptureFinished);
  }

  // ============================================================
  // CAPTURE COLLAGE
  // ============================================================

  Future<File?> captureCollage() async {
    getIt<PhotosManager>().chosen.clear();
    getIt<PhotosManager>().chosen.add(0);

    final stopwatch = Stopwatch()..start();

    final pixelRatio =
        getIt<SettingsManager>().settings.output.resolutionMultiplier;

    final format = getIt<SettingsManager>().settings.output.exportFormat;

    final jpgQuality = getIt<SettingsManager>().settings.output.jpgQuality;

    await completer.future;

    getIt<PhotosManager>().outputImage = await collageKey.currentState!
        .getCollageImage(
      createdByMode: CreatedByMode.single,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );

    logDebug('captureCollage took ${stopwatch.elapsed}');

    return await getIt<PhotosManager>().writeOutput();
  }

  // ============================================================
  // COUNTER FINISHED
  // ============================================================

  Future<void> onCounterFinished() async {
    showFlash = true;
    showCounter = false;

    await Future.delayed(flashAnimationDuration);

    showFlash = false;
    showSpinner = true;

    await Future.delayed(minimumContinueWait);

    // Flash is now not actually complete,
    // but after this time we do not care about it anymore.
    flashComplete = true;

    navigateAfterCapture();
  }

  // ============================================================
  // CAPTURE FINISHED
  // ============================================================

  Future<void> onCaptureFinished() async {
    if (getIt<ProjectManager>().settings.singlePhotoIsCollage) {
      await captureCollage();
    } else {
      getIt<PhotosManager>().outputImage =
          getIt<PhotosManager>().photos.last.data;

      await getIt<PhotosManager>().writeOutput();
    }

    captureComplete = true;

    navigateAfterCapture();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) {
      return;
    }

    getIt<StatsManager>().addCreatedSinglePhoto();

    router.go(ShareScreen.defaultRoute);
  }

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  SingleCaptureScreenViewModelBase({required super.contextAccessor});
}
