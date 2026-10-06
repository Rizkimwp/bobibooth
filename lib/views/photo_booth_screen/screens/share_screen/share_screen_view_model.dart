import 'dart:io';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/models/photo_template.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';

part 'share_screen_view_model.g.dart';

class ShareScreenViewModel = ShareScreenViewModelBase
    with _$ShareScreenViewModel;

abstract class ShareScreenViewModelBase extends ScreenViewModelBase with Store {
  ShareScreenViewModelBase({required super.contextAccessor});

  // ==============================================================
  // EXISTING
  // ==============================================================

  bool get displayConfetti => getIt<ProjectManager>().settings.displayConfetti;

  bool get showGetQrButton => getIt<ProjectManager>().settings.showGetQrButton;

  late final ConfettiController confettiController = ConfettiController(
    duration: const Duration(milliseconds: 100),
  )..play();

  Uint8List get outputImage => getIt<PhotosManager>().outputImage!;

  @observable
  late String printText = localizations.genericPrintButton;

  @observable
  bool printEnabled = true;

  @readonly
  double? _uploadProgress;

  @readonly
  bool _uploadFailed = false;

  @readonly
  String? _qrUrl;

  @readonly
  File? _file;

  @readonly
  Size? _imageSize;

  // ==============================================================
  // TEMPLATE EDITOR
  // ==============================================================

  /// Foto yang tersedia untuk dimasukkan ke template.
  ///
  /// Contoh:
  ///
  /// availablePhotos = [0, 1, 2, 3]
  ///
  /// Artinya ada 4 foto hasil capture yang bisa diklik.
  @observable
  ObservableList<int> availablePhotos = ObservableList<int>();

  /// true = masih memilih foto untuk slot template.
  /// false = sudah menjadi halaman hasil akhir.
  @observable
  bool isTemplateEditing = true;

  /// Mencegah initialize dipanggil berkali-kali.
  @observable
  bool templateInitialized = false;

  // ==============================================================
  // TEMPLATE
  // ==============================================================

  PhotoTemplate? get selectedTemplate =>
      getIt<ProjectManager>().selectedCustomTemplate;

  bool get hasCustomTemplate => selectedTemplate != null;

  int get templatePhotoCount => selectedTemplate?.photoCount ?? 0;

  int get assignedPhotoCount => getIt<PhotosManager>().chosen.length;

  bool get allSlotsFilled {
    final template = selectedTemplate;

    if (template == null) {
      return false;
    }

    return assignedPhotoCount >= template.photoCount;
  }

  int get nextSlot => assignedPhotoCount + 1;

  bool isPhotoAssigned(int photoIndex) {
    return getIt<PhotosManager>().chosen.contains(photoIndex);
  }

  // ==============================================================
  // INITIALIZE
  // ==============================================================

  @action
  void initializeTemplateEditor() {
    if (templateInitialized) {
      return;
    }

    templateInitialized = true;

    final photosManager = getIt<PhotosManager>();

    // chosen dari CollageMaker berisi foto yang dipilih user.
    //
    // Simpan dulu sebagai availablePhotos.
    availablePhotos
      ..clear()
      ..addAll(photosManager.chosen);

    // Sekarang chosen dipakai khusus sebagai:
    //
    // slot 1 -> chosen[0]
    // slot 2 -> chosen[1]
    // slot 3 -> chosen[2]
    // dst.
    photosManager.chosen.clear();

    isTemplateEditing = hasCustomTemplate;
  }

  // ==============================================================
  // ASSIGN PHOTO
  // ==============================================================

  @action
  void assignPhoto(int photoIndex) {
    if (!isTemplateEditing) {
      return;
    }

    final photosManager = getIt<PhotosManager>();

    // Foto yang sama tidak boleh dimasukkan dua kali.
    if (photosManager.chosen.contains(photoIndex)) {
      return;
    }

    final template = selectedTemplate;

    if (template == null) {
      return;
    }

    // Jangan melebihi jumlah slot.
    if (photosManager.chosen.length >= template.photoCount) {
      return;
    }

    // Pastikan foto memang berasal dari daftar available.
    if (!availablePhotos.contains(photoIndex)) {
      return;
    }

    photosManager.chosen.add(photoIndex);
  }

  // ==============================================================
  // REMOVE PHOTO FROM SLOT
  // ==============================================================

  @action
  void removePhotoFromSlot(int photoIndex) {
    final photosManager = getIt<PhotosManager>();

    photosManager.chosen.remove(photoIndex);
  }

  // ==============================================================
  // RESET TEMPLATE
  // ==============================================================

  @action
  void resetTemplateAssignments() {
    getIt<PhotosManager>().chosen.clear();
  }

  // ==============================================================
  // GENERATE
  // ==============================================================

  @action
  Future<void> generateTemplate({
    required GlobalKey<PhotoCollageState> collageKey,
  }) async {
    if (!isTemplateEditing) {
      return;
    }

    if (!allSlotsFilled) {
      return;
    }

    final collageState = collageKey.currentState;

    if (collageState == null) {
      throw StateError('PhotoCollage is not ready yet.');
    }

    final settingsManager = getIt<SettingsManager>();

    final photosManager = getIt<PhotosManager>();

    final pixelRatio = settingsManager.settings.output.resolutionMultiplier;

    final format = settingsManager.settings.output.exportFormat;

    final jpgQuality = settingsManager.settings.output.jpgQuality;

    final exportImage = await collageState.getCollageImage(
      createdByMode: CreatedByMode.multi,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );

    if (exportImage == null) {
      throw StateError('Failed to generate collage image.');
    }

    photosManager.outputImage = exportImage;

    await photosManager.writeOutput();

    getIt<StatsManager>().addCreatedMultiCapturePhoto();

    isTemplateEditing = false;
  }

  // ==============================================================
  // IMAGE
  // ==============================================================

  void onImageDecoded(Size size) {
    _imageSize = size;
  }

  // ==============================================================
  // CONFETTI COLORS
  // ==============================================================

  List<Color>? getColors() {
    if (!getIt<ProjectManager>().settings.customColorConfetti) {
      return null;
    }

    final theme = FluentTheme.of(contextAccessor.buildContext);

    final accentColor = HSLColor.fromColor(theme.accentColor);

    final List<double> lValues = [0.2, 0.4, 0.5, 0.7, 0.9, 1];

    final accentColorsHSL = lValues.map(
      (e) => HSLColor.fromAHSL(1, accentColor.hue, accentColor.saturation, e),
    );

    return accentColorsHSL.map((e) => e.toColor()).toList();
  }

  CaptureMode get captureMode => getIt<PhotosManager>().captureMode;

  bool get canRetake {
    switch (captureMode) {
      case CaptureMode.single:
        return true;

      case CaptureMode.collage:
        return getIt<ProjectManager>().settings.collageMode !=
            CollageMode.userSelection;
    }
  }

  String get backText {
    return canRetake
        ? localizations.shareScreenRetakeButton
        : localizations.shareScreenChangeButton;
  }

  // ==============================================================
  // FIREFOX SEND
  // ==============================================================

  String get ffSendUrl =>
      getIt<SettingsManager>().settings.output.firefoxSendServerUrl;

  Future<void> uploadPhotoToSend() async {
    _file ??=
        getIt<PhotosManager>().lastPhotoFile ??
        await getIt<PhotosManager>().getOutputImageAsTempFile();

    final ext = getIt<SettingsManager>().settings.output.exportFormat.name
        .toLowerCase();

    final formatter = DateFormat('HHmmss');

    final filename =
        "MomentoBooth "
        "${formatter.format(DateTime.now())}"
        ".$ext";

    final stream = ffsendUploadFile(
      filePath: _file!.path,
      hostUrl: ffSendUrl,
      downloadFilename: filename,
      controlCommandTimeout: getIt<SettingsManager>()
          .settings
          .output
          .firefoxSendControlCommandTimeout,
      transferTimeout:
          getIt<SettingsManager>().settings.output.firefoxSendTransferTimeout,
    );

    _uploadProgress = 0.0;
    _uploadFailed = false;

    stream
        .listen((event) async {
          if (event.isFinished) {
            logDebug("Upload complete: ${event.downloadUrl}");

            await Future.delayed(const Duration(milliseconds: 500));

            _qrUrl = event.downloadUrl;
            _uploadProgress = null;

            getIt<StatsManager>().addUploadedPhoto();
          } else {
            logDebug(
              "Uploading: "
              "${event.transferredBytes}/"
              "${event.totalBytes} bytes",
            );

            final total = event.totalBytes ?? 0;

            if (total > 0) {
              _uploadProgress = event.transferredBytes / total;
            }
          }
        })
        .onError((x) async {
          logError(
            "Upload failed, "
            "file path: ${_file!.path}",
            x,
          );

          await Future.delayed(const Duration(seconds: 1));

          _uploadProgress = null;
          _uploadFailed = true;
        });
  }
}
