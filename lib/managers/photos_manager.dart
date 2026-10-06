import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/capture_state.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart'
    show basename, join; // Without show mobx complains
import 'package:path_provider/path_provider.dart';

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

/// Class containing global state for photos in the app.
abstract class PhotosManagerBase with Store, Logger {
  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  @observable
  bool cameraUnavailable = false;

  @observable
  String? cameraErrorMessage;

  @observable
  ObservableList<PhotoCapture> photos = ObservableList<PhotoCapture>();

  @observable
  Uint8List? outputImage;

  @observable
  ObservableList<int> chosen = ObservableList<int>();

  @observable
  CaptureMode captureMode = CaptureMode.single;

  @computed
  bool get showLiveViewBackground =>
      photos.isEmpty && captureMode == CaptureMode.single;

  // ============================================================
  // OUTPUT
  // ============================================================

  Directory get outputDir => getIt<ProjectManager>().getOutputDir();

  int photoNumber = 0;

  bool photoNumberChecked = false;

  final String baseName = "MomentoBooth-image";

  Iterable<PhotoCapture> get chosenPhotos =>
      chosen.map((choice) => photos[choice]);

  File? _lastPhotoFile;

  File? get lastPhotoFile => _lastPhotoFile;

  // ============================================================
  // RESET
  // ============================================================

  @action
  void reset({bool advance = true}) {
    photos.clear();
    chosen.clear();

    captureMode = CaptureMode.single;

    if (advance) {
      photoNumber++;
      _lastPhotoFile = null;
    }
  }

  // ============================================================
  // WRITE OUTPUT
  // ============================================================

  @action
  Future<File?> writeOutput({bool advance = false}) async {
    if (outputImage == null) {
      return null;
    }

    if (!photoNumberChecked) {
      photoNumber = await findLastImageNumber() + 1;

      photoNumberChecked = true;
    }

    final fileExtension = getIt<SettingsManager>()
        .settings
        .output
        .exportFormat
        .name
        .toLowerCase();

    final filePath = join(
      outputDir.path,
      '$baseName-'
      '${photoNumber.toString().padLeft(4, '0')}'
      '.$fileExtension',
    );

    if (advance) {
      photoNumber++;
    }

    final file = await writeBytesToFileLocked(filePath, outputImage!);

    _lastPhotoFile = file;

    return file;
  }

  // ============================================================
  // FIND LAST IMAGE NUMBER
  // ============================================================

  @action
  Future<int> findLastImageNumber() async {
    if (!outputDir.existsSync()) {
      outputDir.createSync();
    }

    final fileListBefore = await outputDir.list().toList();

    final matchingFiles = fileListBefore.whereType<File>().where(
      (file) => basename(file.path).startsWith(baseName),
    );

    if (matchingFiles.isEmpty) {
      return 0;
    }

    final lastImg = matchingFiles.last;

    final pattern = RegExp(r'\d+');

    final match = pattern.firstMatch(basename(lastImg.path));

    return match != null ? int.parse(match.group(0) ?? "0") : 0;
  }

  // ============================================================
  // TEMP OUTPUT
  // ============================================================

  Future<File> getOutputImageAsTempFile() async {
    final Directory tempDir = await getTemporaryDirectory();

    final fileExtension = getIt<SettingsManager>()
        .settings
        .output
        .exportFormat
        .name
        .toLowerCase();

    final filePath = join(tempDir.path, 'image.$fileExtension');

    return await writeBytesToFileLocked(filePath, outputImage!);
  }

  // ============================================================
  // PDF
  // ============================================================

  Future<Uint8List> getOutputPDF(PrintSize printSize) {
    return getImagePdfWithPageSize(outputImage!, printSize);
  }

  // ============================================================
  // GET CURRENT CAPTURER
  //
  // PENTING:
  // gPhoto2Camera TIDAK BOLEH menggunakan "!"
  //
  // Kalau kamera belum siap, return null.
  // ============================================================

  PhotoCaptureMethod? get capturer {
    final captureMethod =
        getIt<SettingsManager>().settings.hardware.captureMethod;

    switch (captureMethod) {
      // ----------------------------------------------------------
      // LIVE VIEW SOURCE
      // ----------------------------------------------------------

      case CaptureMethod.liveViewSource:
        return LiveViewStreamSnapshotCapturer();

      // ----------------------------------------------------------
      // SONY IMAGING EDGE
      // ----------------------------------------------------------

      case CaptureMethod.sonyImagingEdgeDesktop:
        return SonyRemotePhotoCapture(
          getIt<SettingsManager>().settings.hardware.captureLocation,
        );

      // ----------------------------------------------------------
      // GPHOTO2
      // ----------------------------------------------------------

      case CaptureMethod.gPhoto2:
        final camera = getIt<LiveViewManager>().gPhoto2Camera;

        if (camera == null) {
          logWarning('GPhoto2 camera belum siap.');

          return null;
        }

        return camera;
    }
  }

  // ============================================================
  // DIRECT PHOTO CAPTURE
  // ============================================================

  Future<PhotoCapture?> directPhotoCapture() async {
    final capturer = this.capturer;

    // ----------------------------------------------------------
    // CAMERA BELUM SIAP
    // ----------------------------------------------------------

    if (capturer == null) {
      logWarning(
        'Direct capture dibatalkan: '
        'camera belum siap.',
      );

      return null;
    }

    try {
      await capturer.clearPreviousEvents();

      await captureAndGetPhoto(capturer, () {});

      // --------------------------------------------------------
      // JANGAN return photos.last kalau capture gagal
      // --------------------------------------------------------

      if (photos.isEmpty) {
        return null;
      }

      return photos.last;
    } catch (error, stackTrace) {
      logWarning(
        'Direct photo capture gagal: '
        '$error\n'
        '$stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // CAPTURE NOW
  //
  // DIPAKAI OLEH MANUAL TAKE PHOTO
  // SETELAH COUNTDOWN SELESAI
  // ============================================================

  Future<void> captureNow(VoidCallback onCaptureFinished) async {
    // ----------------------------------------------------------
    // AMBIL CAMERA
    // ----------------------------------------------------------

    final capturer = this.capturer;

    // ----------------------------------------------------------
    // CAMERA BELUM SIAP
    // ----------------------------------------------------------

    if (capturer == null) {
      logWarning(
        'Capture dibatalkan: '
        'camera belum siap.',
      );

      onCaptureFinished();

      return;
    }

    try {
      // --------------------------------------------------------
      // CLEAR PREVIOUS CAMERA EVENTS
      // --------------------------------------------------------

      await capturer.clearPreviousEvents();

      // --------------------------------------------------------
      // CAPTURE
      // --------------------------------------------------------

      await captureAndGetPhoto(capturer, onCaptureFinished);
    } catch (error, stackTrace) {
      logWarning(
        'Capture now gagal: '
        '$error\n'
        '$stackTrace',
      );

      onCaptureFinished();

      getIt<MqttManager>().publishCaptureState(CaptureState.idle);
    }
  }

  // ============================================================
  // ORIGINAL DELAYED CAPTURE
  // ============================================================

  void initiateDelayedPhotoCapture(
    VoidCallback onCaptureFinished, {
    int? captureDelayOverride,
  }) {
    // ----------------------------------------------------------
    // GET CAMERA
    // ----------------------------------------------------------

    final capturer = this.capturer;

    // ----------------------------------------------------------
    // CAMERA BELUM SIAP
    // ----------------------------------------------------------

    if (capturer == null) {
      logWarning(
        'Delayed capture dibatalkan: '
        'camera belum siap.',
      );

      onCaptureFinished();

      return;
    }

    // ----------------------------------------------------------
    // CLEAR EVENTS
    // ----------------------------------------------------------

    capturer.clearPreviousEvents();

    // ----------------------------------------------------------
    // SETTINGS
    // ----------------------------------------------------------

    final int counterStart =
        captureDelayOverride ??
        getIt<SettingsManager>().settings.captureDelaySeconds;

    final int autoFocusMsBeforeCapture = getIt<SettingsManager>()
        .settings
        .hardware
        .gPhoto2AutoFocusMsBeforeCapture;

    // ----------------------------------------------------------
    // PHOTO DELAY
    // ----------------------------------------------------------

    final Duration photoDelay =
        Duration(seconds: counterStart) -
        capturer.captureDelay +
        flashStartDuration;

    final Duration autoFocusDelay =
        photoDelay - Duration(milliseconds: autoFocusMsBeforeCapture);

    // ----------------------------------------------------------
    // AUTO FOCUS
    // ----------------------------------------------------------

    if (autoFocusMsBeforeCapture > 0 &&
        autoFocusDelay > Duration.zero &&
        capturer is GPhoto2Camera) {
      Future.delayed(autoFocusDelay).then((_) {
        try {
          capturer.autoFocus();
        } catch (error, stackTrace) {
          logWarning(
            'Auto focus gagal: '
            '$error\n'
            '$stackTrace',
          );
        }
      });
    }

    // ----------------------------------------------------------
    // CAPTURE
    // ----------------------------------------------------------

    Future.delayed(photoDelay).then((_) {
      captureAndGetPhoto(capturer, onCaptureFinished);
    });

    // ----------------------------------------------------------
    // MQTT
    // ----------------------------------------------------------

    getIt<MqttManager>().publishCaptureState(CaptureState.countdown);
  }

  // ============================================================
  // ACTUAL CAPTURE
  // ============================================================

  Future<void> captureAndGetPhoto(
    PhotoCaptureMethod capturer,
    VoidCallback onCaptureFinished,
  ) async {
    getIt<MqttManager>().publishCaptureState(CaptureState.capturing);

    cameraUnavailable = false;
    cameraErrorMessage = null;

    try {
      final image = await capturer.captureAndGetPhoto();

      getIt<StatsManager>().addCapturedPhoto();

      photos.add(image);

      logDebug('Photo berhasil diambil. Total photo: ${photos.length}');
    } catch (error, stackTrace) {
      logWarning('Camera capture gagal: $error');

      logWarning('$stackTrace');

      cameraUnavailable = true;

      cameraErrorMessage = _getCameraErrorMessage(error);

      logWarning('Photo tidak ditambahkan karena capture gagal.');
    } finally {
      onCaptureFinished();

      getIt<MqttManager>().publishCaptureState(CaptureState.idle);
    }
}
}

String _getCameraErrorMessage(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('null check operator')) {
    return 'Kamera belum siap atau live view tidak tersedia.';
  }

  if (message.contains('camera')) {
    return error.toString();
  }

  return 'Kamera tidak tersedia. Silakan periksa koneksi kamera.';
}
// ============================================================
// CAPTURE MODE
// ============================================================

enum CaptureMode {
  single(0, "Single"),

  collage(1, "Collage");

  final int value;

  final String name;

  const CaptureMode(this.value, this.name);
}
