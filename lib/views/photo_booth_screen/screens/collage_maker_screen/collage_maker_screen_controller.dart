import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback_cancellation.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';

class CollageMakerScreenController
    extends ScreenControllerBase<CollageMakerScreenViewModel> {
  late final ActivityTimeoutCallback activityTimeoutCallbackRequest;

  final GlobalKey<PhotoCollageState> collageKey =
      GlobalKey<PhotoCollageState>();

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    activityTimeoutCallbackRequest = ActivityTimeoutCallback(
      onActivityTimeout: onTimeout,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      activityTimeoutCallbackRequest.dispatch(
        contextAccessor.buildContext,
      );
    });
  }

  // ==============================================================
  // TEMPLATE
  // ==============================================================

  void onTemplateContinue() {
    final projectManager = getIt<ProjectManager>();

    if (projectManager.selectedCustomTemplate == null) {
      return;
    }

    viewModel.selectTemplateStep();
  }

  void onBackToTemplate() {
    viewModel.backToTemplateStep();

    getIt<PhotosManager>().chosen.clear();
  }

  // ==============================================================
  // PHOTO SELECTION
  // ==============================================================

  void onTogglePicture(int image) {
    final photosManager = getIt<PhotosManager>();

    // Remove if already selected.
    if (photosManager.chosen.contains(image)) {
      photosManager.chosen.remove(image);
      return;
    }

    final projectManager = getIt<ProjectManager>();
    final selectedTemplate = projectManager.selectedCustomTemplate;

    // Custom template has a fixed number of slots.
    if (selectedTemplate != null) {
      final maxPhotos = selectedTemplate.photoCount;

      if (photosManager.chosen.length >= maxPhotos) {
        return;
      }
    }

    photosManager.chosen.add(image);
  }

  // ==============================================================
  // TIMEOUT
  // ==============================================================

  Future<void> onTimeout() async {
    final photosManager = getIt<PhotosManager>();

    if (photosManager.chosen.isEmpty) {
      return;
    }

    final projectManager = getIt<ProjectManager>();
    final template = projectManager.selectedCustomTemplate;

    // For custom templates, do not generate here.
    // The user must finish assigning photos in ShareScreen.
    if (template != null) {
      router.go(ShareScreen.defaultRoute);
      return;
    }

    // Legacy behavior.
    await viewModel.generateCollage(
      collageKey: collageKey,
    );
  }

  // ==============================================================
  // CONTINUE
  // ==============================================================

  Future<void> onContinueTap() async {
    final photosManager = getIt<PhotosManager>();
    final projectManager = getIt<ProjectManager>();

    if (photosManager.chosen.isEmpty) {
      return;
    }

    final selectedTemplate = projectManager.selectedCustomTemplate;

    if (selectedTemplate != null) {
      if (photosManager.chosen.length < selectedTemplate.photoCount) {
        return;
      }

      // IMPORTANT:
      // Do not generate here.
      //
      // The selected photos will be moved to ShareScreen,
      // where the user assigns them to the template slots.
      router.go(ShareScreen.defaultRoute);
      return;
    }

    // Legacy template behavior remains unchanged.
    await viewModel.generateCollage(
      collageKey: collageKey,
    );

    router.go(ShareScreen.defaultRoute);
  }

  @override
  void dispose() {
    ActivityTimeoutCallbackCancellation(
      onActivityTimeout: onTimeout,
    ).dispatch(
      contextAccessor.buildContext,
    );

    super.dispose();
  }
}