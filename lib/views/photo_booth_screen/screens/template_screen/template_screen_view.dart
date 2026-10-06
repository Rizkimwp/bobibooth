import 'dart:io';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/models/photo_template.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_view_model.dart';

class TemplateScreenView
    extends ScreenViewBase<TemplateScreenViewModel, TemplateScreenController> {
  const TemplateScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A13), Color(0xFF0D3526), Color(0xFF0A241A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header,
            Expanded(
              child: Observer(
                builder: (_) {
                  final templates = viewModel.templates;

                  if (templates.isEmpty) {
                    return _emptyState;
                  }

                  return _templateGrid(templates);
                },
              ),
            ),
            _footer,
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget get _header {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 20),
      child: Row(
        children: [
          Observer(
            builder: (_) {
              final count = viewModel.templates.length;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Text(
                  '$count Templates',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          FilledButton(
            onPressed: controller.onCreateTemplate,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.add, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Create Template',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TEMPLATE GRID
  // ==============================================================

  Widget _templateGrid(List<PhotoTemplate> templates) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        if (constraints.maxWidth < 850) {
          columns = 2;
        }

        if (constraints.maxWidth < 550) {
          columns = 1;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 30),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 22,
            mainAxisSpacing: 22,
            childAspectRatio: 0.72,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return _templateCard(templates[index], index);
          },
        );
      },
    );
  }

  // ==============================================================
  // TEMPLATE CARD
  // ==============================================================

  Widget _templateCard(PhotoTemplate template, int index) {
    return Observer(
      builder: (_) {
        final selected = viewModel.isSelected(template);
        final hovered = viewModel.hoveredIndex == index;

        return MouseRegion(
          onEnter: (_) {
            controller.onHoverTemplate(index);
          },
          onExit: (_) {
            controller.onHoverTemplate(null);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, hovered ? -5 : 0, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF123D2E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5ED39B)
                    : hovered
                    ? const Color(0xFF367E60)
                    : Colors.white.withAlpha(18),
                width: selected || hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(hovered || selected ? 70 : 35),
                  blurRadius: hovered || selected ? 24 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _templatePreview(template, selected: selected),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        FluentIcons.photo2,
                        size: 15,
                        color: Color(0xFF8FCDB3),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        '${template.photoCount} Photos',
                        style: const TextStyle(
                          color: Color(0xFF9BC7B5),
                          fontSize: 13,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        '${template.width.toInt()} × '
                        '${template.height.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF719786),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      onPressed: () {
                        controller.onSelectTemplate(template);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected
                                  ? FluentIcons.check_mark
                                  : FluentIcons.check_list,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selected ? 'Selected' : 'Select Template',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // TEMPLATE PREVIEW
  // ==============================================================

  Widget _templatePreview(PhotoTemplate template, {required bool selected}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF06110C),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final templateRatio = template.width / template.height;

            final availableRatio = constraints.maxWidth / constraints.maxHeight;

            double previewWidth;
            double previewHeight;

            if (availableRatio > templateRatio) {
              previewHeight = constraints.maxHeight;
              previewWidth = previewHeight * templateRatio;
            } else {
              previewWidth = constraints.maxWidth;
              previewHeight = previewWidth / templateRatio;
            }

            final scaleX = previewWidth / template.width;

            final scaleY = previewHeight / template.height;

            return Center(
              child: SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    _backgroundLayer(template),

                    ...template.photos.map((photo) {
                      return _photoPlaceholder(photo, scaleX, scaleY);
                    }),

                    _foregroundLayer(template),

                    if (selected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF5ED39B),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(2),
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

  // ==============================================================
  // BACKGROUND
  // ==============================================================

  Widget _backgroundLayer(PhotoTemplate template) {
    if (template.backPath == null) {
      return const Positioned.fill(child: ColoredBox(color: Color(0xFF101B16)));
    }

    return Positioned.fill(
      child: Image.file(
        File(template.backPath!),
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) {
          return const ColoredBox(color: Color(0xFF101B16));
        },
      ),
    );
  }

  // ==============================================================
  // FOREGROUND
  // ==============================================================

  Widget _foregroundLayer(PhotoTemplate template) {
    if (template.frontPath == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Image.file(
        File(template.frontPath!),
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) {
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ==============================================================
  // PHOTO PLACEHOLDER
  // ==============================================================

  Widget _photoPlaceholder(
    TemplatePhotoPosition photo,
    double scaleX,
    double scaleY,
  ) {
    final angle = photo.rotation * math.pi / 180;

    return Positioned(
      left: photo.x * scaleX,
      top: photo.y * scaleY,
      width: photo.width * scaleX,
      height: photo.height * scaleY,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C3027),
            border: Border.all(color: Colors.white.withAlpha(45), width: 1),
          ),
          child: const Center(
            child: Icon(FluentIcons.photo, size: 24, color: Color(0xFF587A6B)),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget get _emptyState {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FluentIcons.picture,
              size: 32,
              color: Color(0xFF78A993),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No templates found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Add a custom template to the Templates folder.',
            style: TextStyle(color: Color(0xFF91B2A3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // FOOTER
  // ==============================================================

  Widget get _footer {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 22),
      child: Row(
        children: [
          const Icon(FluentIcons.info, size: 14, color: Color(0xFF729889)),

          const SizedBox(width: 8),

          const Text(
            'Choose a template before starting your photo session.',
            style: TextStyle(color: Color(0xFF729889), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
