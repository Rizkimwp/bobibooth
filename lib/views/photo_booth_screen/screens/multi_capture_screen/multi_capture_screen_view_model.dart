import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

part 'multi_capture_screen_view_model.g.dart';

class MultiCaptureScreenViewModel = MultiCaptureScreenViewModelBase
    with _$MultiCaptureScreenViewModel;

abstract class MultiCaptureScreenViewModelBase extends ScreenViewModelBase
    with Store {
  // ============================================================
  // CAMERA
  // ============================================================

  bool flashComplete = false;
  bool captureComplete = false;

  // ============================================================
  // SETTINGS
  // ============================================================

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;

  double get aspectRatio =>
      getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;

  double get collageAspectRatio =>
      getIt<SettingsManager>().settings.collageAspectRatio;

  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  PhotosManager get photosManager => getIt<PhotosManager>();

  // ============================================================
  // STATE
  // ============================================================

  /// Countdown sedang ditampilkan.
  @observable
  bool showCounter = false;

  /// Efek flash.
  @observable
  bool showFlash = false;

  /// Kamera sedang mengambil / memproses foto.
  @observable
  bool showSpinner = false;

  /// Sedang dalam satu siklus capture.
  @observable
  bool isCapturing = false;

  /// User boleh menekan TAKE PHOTO.
  @observable
  bool waitingForTrigger = false;

  /// Sedang melakukan pengecekan kamera ketika screen dibuka.
  @observable
  bool checkingCamera = true;

  // ============================================================
  // CAMERA STATE
  // ============================================================

  @computed
  bool get cameraUnavailable => photosManager.cameraUnavailable;

  @computed
  String? get cameraErrorMessage => photosManager.cameraErrorMessage;

  // ============================================================
  // PHOTO STATE
  // ============================================================

  @computed
  int get capturedPhotos => photosManager.photos.length;

  @computed
  int get photoNumber {
    return min(maxPhotos, capturedPhotos + 1);
  }

  @computed
  int get currentPhotoNumber {
    return photoNumber;
  }

  @computed
  bool get allPhotosCaptured {
    return capturedPhotos >= maxPhotos;
  }

  // ============================================================
  // FLASH
  // ============================================================

  @computed
  double get opacity {
    return showFlash ? 1.0 : 0.0;
  }

  @computed
  Curve get flashAnimationCurve {
    return Curves.easeOutQuart;
  }

  @computed
  Duration get flashAnimationDuration {
    return showFlash ? flashStartDuration : flashEndDuration;
  }

  // ============================================================
  // COLLAGE
  // ============================================================

  final GlobalKey<PhotoCollageState> collageKey =
      GlobalKey<PhotoCollageState>();

  final Completer<void> completer = Completer<void>();

  late final bool enablePhotoCollageWidget;

  void collageReady() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  Future<File?> captureCollage() async {
    final stopwatch = Stopwatch()..start();

    final pixelRatio =
        getIt<SettingsManager>().settings.output.resolutionMultiplier;

    final format = getIt<SettingsManager>().settings.output.exportFormat;

    final jpgQuality = getIt<SettingsManager>().settings.output.jpgQuality;

    await completer.future;

    getIt<PhotosManager>().outputImage = await collageKey.currentState!
        .getCollageImage(
      createdByMode: CreatedByMode.multi,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );

    logDebug('captureCollage took ${stopwatch.elapsed}');

    return await getIt<PhotosManager>().writeOutput();
  }

  // ============================================================
  // MAX PHOTO
  // ============================================================

  final int maxPhotos =
      getIt<ProjectManager>().settings.collageMode.captureCount;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MultiCaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    enablePhotoCollageWidget = true;

    flashComplete = false;
    captureComplete = false;

    showCounter = false;
    showFlash = false;
    showSpinner = false;

    isCapturing = false;
    waitingForTrigger = false;

    checkingCamera = true;

    // Jangan capture.
    // Hanya cek apakah kamera siap.
  }

  // ============================================================
  // INITIAL CAMERA CHECK
  // ============================================================

  // ============================================================
  // TAKE PHOTO
  // ============================================================

  @action
  void triggerCapture() {
    if (cameraUnavailable) {
      return;
    }

    if (isCapturing) {
      return;
    }

    if (allPhotosCaptured) {
      return;
    }

    // ----------------------------------------------------------
    // STATE
    // ----------------------------------------------------------

    isCapturing = true;
    waitingForTrigger = false;

    flashComplete = false;
    captureComplete = false;

    showFlash = false;
    showSpinner = false;
    showCounter = true;

    // ----------------------------------------------------------
    // DEBUG
    // ----------------------------------------------------------

    logDebug(
      'MULTI CAPTURE START '
      'photo=${capturedPhotos + 1}/$maxPhotos',
    );

    // ----------------------------------------------------------
    // CAPTURE
    // ----------------------------------------------------------

    photosManager.initiateDelayedPhotoCapture(onCaptureFinished);
  }

  // ============================================================
  // COUNTDOWN FINISHED
  // ============================================================

  @action
  Future<void> onCounterFinished() async {
    showCounter = false;

    // ----------------------------------------------------------
    // FLASH
    // ----------------------------------------------------------

    showFlash = true;

    await Future.delayed(flashAnimationDuration);

    showFlash = false;

    // ----------------------------------------------------------
    // SPINNER
    // ----------------------------------------------------------

    if (isCapturing) {
      showSpinner = true;
    }
  }

  // ============================================================
  // CAMERA CALLBACK
  // ============================================================

  @action
  void onCaptureFinished() {
    showSpinner = false;
    showCounter = false;
    showFlash = false;

    isCapturing = false;

    // ----------------------------------------------------------
    // CAMERA ERROR
    // ----------------------------------------------------------

    if (cameraUnavailable) {
      waitingForTrigger = false;
      return;
    }

    // ----------------------------------------------------------
    // SEMUA FOTO SELESAI
    // ----------------------------------------------------------

    if (allPhotosCaptured) {
      waitingForTrigger = false;
      return;
    }

    // ----------------------------------------------------------
    // FOTO BERIKUTNYA
    // ----------------------------------------------------------

    waitingForTrigger = true;
  }

  // ============================================================
  // RETRY CAMERA
  // ============================================================

  // ============================================================
  // DONE
  // ============================================================

  Future<void> navigateAfterCapture() async {
    // Belum semua foto.
    if (!allPhotosCaptured) {
      return;
    }

    // Masih capture.
    if (isCapturing) {
      return;
    }

    // Kamera bermasalah.
    if (cameraUnavailable) {
      return;
    }

    waitingForTrigger = false;

    // ==========================================================
    // USER SELECTION
    // ==========================================================

    if (getIt<ProjectManager>().settings.collageMode ==
        CollageMode.userSelection) {
      router.go(CollageMakerScreen.defaultRoute);

      return;
    }

    // ==========================================================
    // AUTO MODE
    // ==========================================================

    photosManager.chosen.clear();

    photosManager.chosen.addAll(
      List.generate(photosManager.photos.length, (index) => index),
    );

    // ==========================================================
    // CREATE COLLAGE
    // ==========================================================

    final value = await captureCollage();

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (value != null) {
      getIt<StatsManager>().addCreatedMultiCapturePhoto();

      router.go(ShareScreen.defaultRoute);

      return;
    }

    // ==========================================================
    // FAILED
    // ==========================================================

    router.go(StartScreen.defaultRoute);
  }

  // ============================================================
  // RESET
  // ============================================================

  @action
  void resetCaptureState() {
    if (isCapturing) {
      return;
    }

    flashComplete = false;
    captureComplete = false;

    showCounter = false;
    showFlash = false;
    showSpinner = false;

    isCapturing = false;

    if (cameraUnavailable || checkingCamera) {
      waitingForTrigger = false;
    } else {
      waitingForTrigger = true;
    }
  }
}
