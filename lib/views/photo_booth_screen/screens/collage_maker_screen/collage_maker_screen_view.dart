import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/photo_template.dart';
import 'package:momento_booth/models/template_kind.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/rotating_collage_box.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';

class CollageMakerScreenView
    extends
        ScreenViewBase<
          CollageMakerScreenViewModel,
          CollageMakerScreenController
        > {
  const CollageMakerScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  // ============================================================
  // BODY
  // ============================================================

  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _header,
            Expanded(
              child: Observer(
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: viewModel.templateSelected
                        ? _photoStep
                        : _templateStep,
                  );
                },
              ),
            ),
            _bottomBar,
          ],
        ),

        Observer(
          builder: (_) {
            if (!viewModel.isGeneratingImage) {
              return const SizedBox.shrink();
            }

            return Center(
              child: LoadingDialog.generic(
                title: localizations.genericOneMomentPlease,
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget get _header {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 25, 35, 15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF176B4D).withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.images,
              color: Color(0xFF176B4D),
              size: 24,
            ),
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.templateSelected
                    ? 'Choose your photos'
                    : 'Choose a template',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                viewModel.templateSelected
                    ? 'Select photos for your chosen template'
                    : 'Select the layout you want to use',
                style: TextStyle(fontSize: 14, color: Colors.grey[100]),
              ),
            ],
          ),

          const Spacer(),

          _stepIndicator,
        ],
      ),
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget get _stepIndicator {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepItem(
          number: 1,
          title: 'Template',
          active: !viewModel.templateSelected,
          completed: viewModel.templateSelected,
        ),
        _stepLine,
        _stepItem(
          number: 2,
          title: 'Photos',
          active: viewModel.templateSelected,
          completed: false,
        ),
      ],
    );
  }

  Widget _stepItem({
    required int number,
    required String title,
    required bool active,
    required bool completed,
  }) {
    final color = active || completed
        ? const Color(0xFF176B4D)
        : Colors.grey[100];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: completed
                ? const Icon(LucideIcons.check, size: 15, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: active ? Colors.white : Colors.grey[180],
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? const Color(0xFF176B4D) : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget get _stepLine {
    return Container(
      width: 45,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey[70],
    );
  }

  // ============================================================
  // STEP 1 - TEMPLATE
  // ============================================================

  Widget get _templateStep {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 10, 35, 15),
      child: Column(children: [Expanded(child: _templateGrid)]),
    );
  }

  // ============================================================
  // TEMPLATE GRID
  // ============================================================

  Widget get _templateGrid {
    return Observer(
      builder: (_) {
        final projectManager = getIt<ProjectManager>();

        final customTemplates = projectManager.customTemplates;

        final defaultTemplates = <_TemplateItem>[
          _TemplateItem.defaultTemplate(
            projectManager.templates[TemplateKind.front]?[2],
            2,
          ),
          _TemplateItem.defaultTemplate(
            projectManager.templates[TemplateKind.front]?[3],
            3,
          ),
          _TemplateItem.defaultTemplate(
            projectManager.templates[TemplateKind.front]?[4],
            4,
          ),
        ].where((e) => e.file != null).toList();

        final items = [
          ...defaultTemplates,
          ...customTemplates.map(
            _TemplateItem.customTemplate,
          ),
        ];

        if (items.isEmpty) {
          return _emptyTemplate;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final crossAxisCount = width > 1100
                ? 5
                : width > 800
                ? 4
                : width > 550
                ? 3
                : 2;

            return GridView.builder(
              padding: const EdgeInsets.only(bottom: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: .82,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return _modernTemplateCard(item);
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TEMPLATE CARD
  // ============================================================

  Widget _modernTemplateCard(_TemplateItem item) {
    final projectManager = getIt<ProjectManager>();

    return Observer(
      builder: (_) {
        final selected = item.isDefault
            ? projectManager.selectedCustomTemplate == null
            : projectManager.selectedCustomTemplate?.id == item.template?.id;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (item.isDefault) {
                projectManager.selectCustomTemplate(null);
              } else {
                projectManager.selectCustomTemplate(item.template);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF176B4D)
                      : const Color(0x18000000),
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(selected ? .10 : .045),
                    blurRadius: selected ? 18 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: const Color(0xFFF4F6F5),
                            padding: const EdgeInsets.all(14),
                            child: _templatePreview(item),
                          ),

                          if (selected)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF176B4D),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.photoCount} photos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[100],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (selected)
                            const Icon(
                              LucideIcons.circleCheck,
                              size: 20,
                              color: Color(0xFF176B4D),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _templatePreview(_TemplateItem item) {
    final file = item.file;

    if (file == null || !file.existsSync()) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9EFEC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(LucideIcons.imageOff, size: 30, color: Color(0xFF789187)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ImageWithLoaderFallback.file(file, fit: BoxFit.contain),
    );
  }

  Widget get _emptyTemplate {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF176B4D).withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.images,
              size: 32,
              color: Color(0xFF176B4D),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No templates available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a template to get started',
            style: TextStyle(color: Colors.grey[100]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2 - PHOTO
  // ============================================================

  Widget get _photoStep {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 10, 35, 15),
      child: Row(
        children: [
          Expanded(flex: 6, child: _photoSelectionCard),
          const SizedBox(width: 25),
          Expanded(flex: 4, child: _selectedTemplatePreview),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO SELECTION CARD
  // ============================================================

  Widget get _photoSelectionCard {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.camera,
                color: Color(0xFF176B4D),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Select photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Observer(
                builder: (_) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF176B4D).withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${viewModel.numSelected} selected',
                      style: const TextStyle(
                        color: Color(0xFF176B4D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          Expanded(child: _photoSelector,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO SELECTOR
  // ============================================================

  Widget get _photoSelector {
    final photosManager = getIt<PhotosManager>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = photosManager.photos.length;

        final crossAxisCount = constraints.maxWidth > 750
            ? 4
            : constraints.maxWidth > 450
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            return _photoCard(index);
          },
        );
      },
    );
  }

  Widget _photoCard(int index) {
    final photosManager = getIt<PhotosManager>();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => controller.onTogglePicture(index),
        child: Observer(
          builder: (_) {
            final isSelected = photosManager.chosen.contains(index);

            final selectedIndex = photosManager.chosen.indexOf(index);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF176B4D)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageWithLoaderFallback.memory(
                      photosManager.photos[index].data,
                      applyRotateFlipCrop: true,
                    ),

                    AnimatedOpacity(
                      opacity: isSelected ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: ColoredBox(
                        color: const Color(0x99000000),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF176B4D),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${selectedIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
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
          },
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED TEMPLATE PREVIEW
  // ============================================================

  Widget get _selectedTemplatePreview {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.layoutTemplate,
                size: 20,
                color: Color(0xFF176B4D),
              ),
              SizedBox(width: 10),
              Text(
                'Selected template',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Expanded(child: _collage,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLLAGE PREVIEW
  // ============================================================

  Widget get _collage {
    final collage = PhotoCollage(
      key: controller.collageKey,
      aspectRatio: 1 / viewModel.collageAspectRatio,
      padding: viewModel.collagePadding,
    );

    return Observer(
      builder: (context) {
        return Center(
          child: RotatingCollageBox(
            turns: -0.25 * viewModel.rotation,
            collage:
                context.theme.collagePreviewTheme.frameBuilder?.call(
                  context,
                  collage,
                ) ??
                collage,
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget get _bottomBar {
    return Container(
      padding: const EdgeInsets.fromLTRB(35, 14, 35, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(.07))),
      ),
      child: Row(
        children: [
          if (viewModel.templateSelected)
            Button(
              onPressed: controller.onBackToTemplate,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.arrowLeft, size: 18),
                    SizedBox(width: 8),
                    Text('Change template'),
                  ],
                ),
              ),
            ),

          const Spacer(),

          Observer(
            builder: (_) {
              if (!viewModel.templateSelected) {
                return _nextTemplateButton;
              }

              return PhotoBoothButton.navigation(
                onPressed: viewModel.numSelected > 0
                    ? controller.onContinueTap
                    : null,
                child: AutoSizeTextAndIcon(
                  text: localizations.genericContinueButton,
                  rightIcon: LucideIcons.arrowRight,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget get _nextTemplateButton {
    return PhotoBoothButton.navigation(
      onPressed:
          getIt<ProjectManager>().selectedCustomTemplate != null ||
              _hasDefaultTemplate
          ? controller.onTemplateContinue
          : null,
      child: const AutoSizeTextAndIcon(
        text: 'Choose photos',
        rightIcon: LucideIcons.arrowRight,
      ),
    );
  }

  bool get _hasDefaultTemplate {
    final projectManager = getIt<ProjectManager>();

    return projectManager.templates[TemplateKind.front]!.values.any(
      (file) => file != null,
    );
  }
}

// ============================================================
// TEMPLATE ITEM
// ============================================================

class _TemplateItem {
  final bool isDefault;
  final File? file;
  final PhotoTemplate? template;
  final int photoCount;

  const _TemplateItem({
    required this.isDefault,
    required this.file,
    required this.template,
    required this.photoCount,
  });

  factory _TemplateItem.defaultTemplate(File? file, int photoCount) {
    return _TemplateItem(
      isDefault: true,
      file: file,
      template: null,
      photoCount: photoCount,
    );
  }

  factory _TemplateItem.customTemplate(PhotoTemplate template) {
    final path = template.frontPath ?? template.backPath;

    return _TemplateItem(
      isDefault: false,
      file: path == null ? null : File(path),
      template: template,
      photoCount: template.photoCount,
    );
  }

  String get title {
    if (isDefault) {
      return 'Default $photoCount Photos';
    }

    return template?.name ?? 'Template';
  }
}
