import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as path;

import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/photo_template.dart';

class CreateTemplateDialog extends StatefulWidget {
  const CreateTemplateDialog({super.key});

  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _nameController = TextEditingController();
  final _widthController = TextEditingController(text: '1200');
  final _heightController = TextEditingController(text: '1800');

  // ============================================================
  // TEMPLATE STATE
  // ============================================================

  int _photoCount = 3;

  String? _backgroundPath;
  String? _foregroundPath;

  bool _isSaving = false;

  /// Slot foto yang sedang diedit.
  List<TemplatePhotoPosition> _photoPositions = [];

  /// Slot yang sedang dipilih.
  int? _selectedPhotoIndex;

  /// Ukuran minimum slot.
  static const double _minSlotSize = 80;

  /// Padding default ketika membuat slot baru.
  static const double _defaultPadding = 80;

  /// Gap default.
  static const double _defaultGap = 30;

  // ============================================================
  // COLORS
  // ============================================================

  static const _green = Color(0xFF6FFFB0);
  static const _greenDark = Color(0xFF00D878);

  static const _surface = Color.fromARGB(255, 249, 246, 246);
  static const _surfaceLight = Color(0xFF111111);
  static const _border = Color(0xFF292929);

  static const _textSecondary = Color(0xFF9A9A9A);

  ProjectManager get projectManager => getIt<ProjectManager>();

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _photoPositions = _generateInitialPositions(
      width: 1200,
      height: 1800,
      count: _photoCount,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILE PICKER
  // ============================================================

  Future<void> _pickBackground() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );

    if (file == null) return;

    setState(() {
      _backgroundPath = file.path;
    });
  }

  Future<void> _pickForeground() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );

    if (file == null) return;

    setState(() {
      _foregroundPath = file.path;
    });
  }

  // ============================================================
  // SLUG
  // ============================================================

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  // ============================================================
  // CANVAS SIZE
  // ============================================================

  double get _canvasWidth {
    return double.tryParse(_widthController.text.trim()) ?? 1200;
  }

  double get _canvasHeight {
    return double.tryParse(_heightController.text.trim()) ?? 1800;
  }

  // ============================================================
  // INITIAL PHOTO POSITIONS
  // ============================================================

  List<TemplatePhotoPosition> _generateInitialPositions({
    required int width,
    required int height,
    required int count,
  }) {
    if (count <= 0) {
      return [];
    }

    const horizontalPadding = _defaultPadding;
    const verticalPadding = 100.0;
    const gap = _defaultGap;

    final availableWidth =
        math.max(100.0, width - horizontalPadding * 2);

    // 1 foto
    if (count == 1) {
      return [
        TemplatePhotoPosition(
          x: horizontalPadding,
          y: verticalPadding,
          width: availableWidth,
          height: math.max(
            _minSlotSize,
            height - verticalPadding * 2,
          ),
        ),
      ];
    }

    // 2 foto
    if (count == 2) {
      final photoWidth =
          math.max(_minSlotSize, (availableWidth - gap) / 2);

      final photoHeight =
          math.max(_minSlotSize, height - verticalPadding * 2);

      return [
        TemplatePhotoPosition(
          x: horizontalPadding,
          y: verticalPadding,
          width: photoWidth,
          height: photoHeight,
        ),
        TemplatePhotoPosition(
          x: horizontalPadding + photoWidth + gap,
          y: verticalPadding,
          width: photoWidth,
          height: photoHeight,
        ),
      ];
    }

    // 3+ foto
    final columns = count <= 3 ? 2 : 2;
    final rows = (count / columns).ceil();

    final photoWidth =
        math.max(_minSlotSize, (availableWidth - gap) / columns);

    final availableHeight =
        math.max(
          _minSlotSize * rows,
          height -
              verticalPadding * 2 -
              gap * (rows - 1),
        );

    final photoHeight =
        math.max(_minSlotSize, availableHeight / rows);

    final positions = <TemplatePhotoPosition>[];

    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      final column = i % columns;

      positions.add(
        TemplatePhotoPosition(
          x: horizontalPadding +
              column * (photoWidth + gap),
          y: verticalPadding +
              row * (photoHeight + gap),
          width: photoWidth,
          height: photoHeight,
        ),
      );
    }

    return positions;
  }

  // ============================================================
  // PHOTO COUNT
  // ============================================================

  void _setPhotoCount(int count) {
    count = count.clamp(1, 6);

    final current = List<TemplatePhotoPosition>.from(
      _photoPositions,
    );

    if (count < current.length) {
      current.removeRange(count, current.length);
    } else {
      final extra = _generateInitialPositions(
        width: _canvasWidth.round(),
        height: _canvasHeight.round(),
        count: count,
      );

      for (var i = current.length; i < count; i++) {
        if (i < extra.length) {
          current.add(extra[i]);
        }
      }
    }

    setState(() {
      _photoCount = count;
      _photoPositions = current;

      if (_selectedPhotoIndex != null &&
          _selectedPhotoIndex! >= current.length) {
        _selectedPhotoIndex = null;
      }
    });
  }

  // ============================================================
  // ADD PHOTO SLOT
  // ============================================================

  void _addPhotoSlot() {
    if (_photoPositions.length >= 6) return;

    final width = _canvasWidth;
    final height = _canvasHeight;

    final slotWidth = math.min(
      450.0,
      width - _defaultPadding * 2,
    );

    final slotHeight = math.min(
      350.0,
      height - _defaultPadding * 2,
    );

    final index = _photoPositions.length;

    // Posisi baru dibuat agak bergeser supaya langsung terlihat.
    final offset = 40.0 * index;

    final newPosition = TemplatePhotoPosition(
      x: math.max(
        0,
        math.min(
          width - slotWidth,
          _defaultPadding + offset,
        ),
      ),
      y: math.max(
        0,
        math.min(
          height - slotHeight,
          _defaultPadding + offset,
        ),
      ),
      width: slotWidth,
      height: slotHeight,
    );

    setState(() {
      _photoPositions = [
        ..._photoPositions,
        newPosition,
      ];

      _photoCount = _photoPositions.length;
      _selectedPhotoIndex = index;
    });
  }

  // ============================================================
  // REMOVE PHOTO SLOT
  // ============================================================

  void _removeSelectedPhoto() {
    final index = _selectedPhotoIndex;

    if (index == null) return;
    if (index < 0 || index >= _photoPositions.length) return;

    final updated = List<TemplatePhotoPosition>.from(
      _photoPositions,
    );

    updated.removeAt(index);

    int? newSelected;

    if (updated.isNotEmpty) {
      newSelected = math.min(index, updated.length - 1);
    }

    setState(() {
      _photoPositions = updated;
      _photoCount = updated.length;
      _selectedPhotoIndex = newSelected;
    });
  }

  // ============================================================
  // RESET LAYOUT
  // ============================================================

  void _resetLayout() {
    final width = _canvasWidth.round();
    final height = _canvasHeight.round();

    setState(() {
      _photoPositions = _generateInitialPositions(
        width: width,
        height: height,
        count: _photoCount,
      );

      _selectedPhotoIndex =
          _photoPositions.isEmpty ? null : 0;
    });
  }

  // ============================================================
  // UPDATE PHOTO POSITION
  // ============================================================

  void _updatePhotoPosition(
    int index, {
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    if (index < 0 || index >= _photoPositions.length) {
      return;
    }

    final old = _photoPositions[index];

    final updated = TemplatePhotoPosition(
      x: x ?? old.x,
      y: y ?? old.y,
      width: width ?? old.width,
      height: height ?? old.height,
      rotation: rotation ?? old.rotation,
    );

    final list = List<TemplatePhotoPosition>.from(
      _photoPositions,
    );

    list[index] = updated;

    setState(() {
      _photoPositions = list;
    });
  }

  // ============================================================
  // CLAMP SLOT
  // ============================================================

  TemplatePhotoPosition _clampPosition(
    TemplatePhotoPosition position,
  ) {
    final canvasWidth = _canvasWidth;
    final canvasHeight = _canvasHeight;

    final width = position.width
        .clamp(_minSlotSize, canvasWidth)
        .toDouble();

    final height = position.height
        .clamp(_minSlotSize, canvasHeight)
        .toDouble();

    final x = position.x
        .clamp(0.0, math.max(0.0, canvasWidth - width))
        .toDouble();

    final y = position.y
        .clamp(0.0, math.max(0.0, canvasHeight - height))
        .toDouble();

    return TemplatePhotoPosition(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: position.rotation,
    );
  }

  // ============================================================
  // DRAG PHOTO SLOT
  // ============================================================

  void _movePhotoSlot(
    int index,
    Offset delta,
    double scale,
  ) {
    if (index < 0 || index >= _photoPositions.length) {
      return;
    }

    final position = _photoPositions[index];

    final dx = delta.dx / scale;
    final dy = delta.dy / scale;

    final next = _clampPosition(
      TemplatePhotoPosition(
        x: position.x + dx,
        y: position.y + dy,
        width: position.width,
        height: position.height,
        rotation: position.rotation,
      ),
    );

    _updatePhotoPosition(
      index,
      x: next.x,
      y: next.y,
    );
  }

  // ============================================================
  // RESIZE PHOTO SLOT
  // ============================================================

  void _resizePhotoSlot(
    int index,
    Offset delta,
    double scale,
  ) {
    if (index < 0 || index >= _photoPositions.length) {
      return;
    }

    final position = _photoPositions[index];

    final dw = delta.dx / scale;
    final dh = delta.dy / scale;

    final next = _clampPosition(
      TemplatePhotoPosition(
        x: position.x,
        y: position.y,
        width: position.width + dw,
        height: position.height + dh,
        rotation: position.rotation,
      ),
    );

    _updatePhotoPosition(
      index,
      width: next.width,
      height: next.height,
    );
  }

  // ============================================================
  // ROTATION
  // ============================================================

  void _rotateSelected(double value) {
    final index = _selectedPhotoIndex;

    if (index == null) return;

    _updatePhotoPosition(
      index,
      rotation: value,
    );
  }

  // ============================================================
  // CREATE TEMPLATE
  // ============================================================

  Future<void> _createTemplate() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      await _showError('Template name is required.');
      return;
    }

    final width = int.tryParse(
      _widthController.text.trim(),
    );

    final height = int.tryParse(
      _heightController.text.trim(),
    );

    if (width == null || width <= 0) {
      await _showError(
        'Width must be a valid number.',
      );
      return;
    }

    if (height == null || height <= 0) {
      await _showError(
        'Height must be a valid number.',
      );
      return;
    }

    if (_backgroundPath == null) {
      await _showError(
        'Please select a background image.',
      );
      return;
    }

    if (_photoPositions.isEmpty) {
      await _showError(
        'Please add at least one photo slot.',
      );
      return;
    }

    final slug = _slugify(name);

    if (slug.isEmpty) {
      await _showError(
        'Template name is invalid.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final templateDir = Directory(
        path.join(
          projectManager.getTemplateDir().path,
          slug,
        ),
      );

      if (await templateDir.exists()) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }

        await _showError(
          'A template with this name already exists.',
        );

        return;
      }

      await templateDir.create(
        recursive: true,
      );

      // ========================================================
      // BACKGROUND
      // ========================================================

      final backgroundExtension = path
          .extension(_backgroundPath!)
          .toLowerCase();

      final backgroundFile = File(
        path.join(
          templateDir.path,
          'back$backgroundExtension',
        ),
      );

      await File(
        _backgroundPath!,
      ).copy(backgroundFile.path);

      // ========================================================
      // FOREGROUND
      // ========================================================

      String? foregroundFileName;

      if (_foregroundPath != null) {
        final foregroundExtension = path
            .extension(_foregroundPath!)
            .toLowerCase();

        final foregroundFile = File(
          path.join(
            templateDir.path,
            'front$foregroundExtension',
          ),
        );

        await File(
          _foregroundPath!,
        ).copy(foregroundFile.path);

        foregroundFileName = foregroundFile.path;
      }

      // ========================================================
      // FINAL POSITIONS
      // ========================================================

      final finalPositions = _photoPositions
          .map(_clampPosition)
          .toList();

      final template = PhotoTemplate(
        id: slug,
        name: name,
        width: width.toDouble(),
        height: height.toDouble(),
        photoCount: finalPositions.length,
        backPath: backgroundFile.path,
        frontPath: foregroundFileName,
        photos: finalPositions,
      );

      // ========================================================
      // JSON
      // ========================================================

      final jsonFile = File(
        path.join(
          templateDir.path,
          'template.json',
        ),
      );

      await jsonFile.writeAsString(
        template.encode(),
      );

      // ========================================================
      // REFRESH
      // ========================================================

      await projectManager.findTemplates();

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      await _showError(
        'Failed to create template:\n$e',
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  Future<void> _showError(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) {
        return ContentDialog(
          title: const Text(
            'Create Template',
          ),
          content: Text(message),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _green.withAlpha(25),
            borderRadius:
                BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 17,
            color: _green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    VoidCallback? onChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          TextBox(
            controller: controller,
            keyboardType:
                TextInputType.number,
            onChanged: (_) {
              if (onChanged != null) {
                onChanged();
              }
            },
            suffix: const Padding(
              padding:
                  EdgeInsets.only(right: 10),
              child: Text(
                'px',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO COUNT
  // ============================================================

  Widget _photoCountSelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              FluentIcons.remove,
              size: 15,
            ),
            onPressed:
                _photoCount <= 1
                    ? null
                    : () {
                        _setPhotoCount(
                          _photoCount - 1,
                        );
                      },
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    '$_photoCount',
                    style:
                        const TextStyle(
                          color: Colors.white,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'photos',
                    style:
                        TextStyle(
                      color:
                          _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              FluentIcons.add,
              size: 15,
            ),
            onPressed:
                _photoCount >= 6
                    ? null
                    : () {
                        _setPhotoCount(
                          _photoCount + 1,
                        );
                      },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _imagePicker({
    required String title,
    required String description,
    required String? filePath,
    required VoidCallback onPressed,
    required IconData icon,
    required bool requiredFile,
  }) {
    final hasFile = filePath != null;

    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: hasFile
              ? _green.withAlpha(100)
              : _border,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: hasFile
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(filePath),
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child:
                      DecoratedBox(
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment
                                .topCenter,
                        end:
                            Alignment
                                .bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black
                              .withAlpha(
                            220,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 10,
                  bottom: 9,
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FluentIcons
                                      .completed,
                                  size: 12,
                                  color:
                                      _green,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child:
                                      Text(
                                    title,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          11,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              path.basename(
                                filePath,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Button(
                        onPressed:
                            onPressed,
                        child:
                            const Text(
                          'Change',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Button(
              onPressed: onPressed,
              style: ButtonStyle(
                padding:
                    WidgetStateProperty
                        .all(
                  const EdgeInsets
                      .symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color: _green
                          .withAlpha(
                        25,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: _green,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          title,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          description,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                _textSecondary,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          requiredFile
                              ? 'Required'
                              : 'Optional',
                          style:
                              TextStyle(
                            color:
                                requiredFile
                                    ? _green
                                    : _textSecondary,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // CANVAS PREVIEW
  // ============================================================

  Widget _buildCanvasPreview(
    BoxConstraints constraints,
  ) {
    final canvasWidth =
        _canvasWidth;
    final canvasHeight =
        _canvasHeight;

    if (canvasWidth <= 0 ||
        canvasHeight <= 0) {
      return const Center(
        child: Text(
          'Invalid canvas size',
        ),
      );
    }

    final maxWidth =
        constraints.maxWidth - 30;

    final maxHeight =
        constraints.maxHeight - 30;

    final scale = math.min(
      maxWidth / canvasWidth,
      maxHeight / canvasHeight,
    );

    final displayWidth =
        canvasWidth * scale;

    final displayHeight =
        canvasHeight * scale;

    return Center(
      child: Container(
        width: displayWidth,
        height: displayHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          boxShadow: const [
            BoxShadow(
              blurRadius: 25,
              spreadRadius: 2,
              color: Colors.black,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ====================================================
            // BACKGROUND
            // ====================================================

            Positioned.fill(
              child: _backgroundPath != null
                  ? Image.file(
                      File(_backgroundPath!),
                      fit: BoxFit.fill,
                    )
                  : Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text(
                          'Background',
                          style: TextStyle(
                            color:
                                Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),

            // ====================================================
            // PHOTO SLOTS
            // ====================================================

            ...List.generate(
              _photoPositions.length,
              (index) {
                final position =
                    _photoPositions[index];

                final isSelected =
                    _selectedPhotoIndex ==
                        index;

                return Positioned(
                  left: position.x * scale,
                  top: position.y * scale,
                  width:
                      position.width * scale,
                  height:
                      position.height * scale,
                  child:
                      _buildPhotoSlot(
                    index: index,
                    position: position,
                    scale: scale,
                    selected:
                        isSelected,
                  ),
                );
              },
            ),

            // ====================================================
            // FOREGROUND
            // ====================================================

            if (_foregroundPath != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.file(
                    File(
                      _foregroundPath!,
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO SLOT
  // ============================================================

  Widget _buildPhotoSlot({
    required int index,
    required TemplatePhotoPosition position,
    required double scale,
    required bool selected,
  }) {
    final rotation =
        position.rotation *
            math.pi /
            180;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,

      onTap: () {
        setState(() {
          _selectedPhotoIndex =
              index;
        });
      },

      onPanStart: (_) {
        setState(() {
          _selectedPhotoIndex =
              index;
        });
      },

      onPanUpdate: (details) {
        if (!selected &&
            _selectedPhotoIndex !=
                index) {
          return;
        }

        _movePhotoSlot(
          index,
          details.delta,
          scale,
        );
      },

      child: Stack(
        clipBehavior:
            Clip.none,
        children: [
          // ======================================================
          // SLOT
          // ======================================================

          Positioned.fill(
            child:
                Transform.rotate(
              angle: rotation,
              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withAlpha(55),
                  border:
                      Border.all(
                    color: selected
                        ? _green
                        : Colors.white
                            .withAlpha(
                            170,
                          ),
                    width: selected
                        ? 2
                        : 1,
                  ),
                ),
                child: Stack(
                  alignment:
                      Alignment.center,
                  children: [
                    Icon(
                      FluentIcons
                          .photo2,
                      size: math.max(
                        18,
                        math.min(
                          32,
                          position.width *
                              scale *
                              0.18,
                        ),
                      ),
                      color: Colors.white
                          .withAlpha(
                        150,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .black
                              .withAlpha(
                            170,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            5,
                          ),
                        ),
                        child: Text(
                          'PHOTO ${index + 1}',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 8,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // RESIZE HANDLE
          // ======================================================

          if (selected)
            Positioned(
              right: -7,
              bottom: -7,
              child:
                  GestureDetector(
                behavior:
                    HitTestBehavior
                        .opaque,
                onPanUpdate:
                    (details) {
                  _resizePhotoSlot(
                    index,
                    details.delta,
                    scale,
                  );
                },
                child: Container(
                  width: 15,
                  height: 15,
                  decoration:
                      BoxDecoration(
                    color: _green,
                    borderRadius:
                        BorderRadius
                            .circular(
                      3,
                    ),
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                   FluentIcons.edit,
                    size: 9,
                    color:
                        Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED SLOT PANEL
  // ============================================================

  Widget _buildSelectedSlotPanel() {
    final index =
        _selectedPhotoIndex;

    if (index == null ||
        index >=
            _photoPositions.length) {
      return Container(
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: _surface,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: _border,
          ),
        ),
        child: const Text(
          'Select a photo slot to edit its position and size.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 10,
          ),
        ),
      );
    }

    final position =
        _photoPositions[index];

    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color: _surface,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: _green.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration:
                    BoxDecoration(
                  color: _green
                      .withAlpha(
                    25,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    7,
                  ),
                ),
                child: const Icon(
                  FluentIcons
                      .photo2,
                  size: 13,
                  color: _green,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  'Photo ${index + 1}',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon:
                    const Icon(
                  FluentIcons
                      .delete,
                  size: 13,
                ),
                onPressed:
                    _removeSelectedPhoto,
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _smallValueBox(
                  label: 'X',
                  value:
                      position.x,
                  onChanged:
                      (value) {
                    _updatePhotoPosition(
                      index,
                      x: value,
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child:
                    _smallValueBox(
                  label: 'Y',
                  value:
                      position.y,
                  onChanged:
                      (value) {
                    _updatePhotoPosition(
                      index,
                      y: value,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _smallValueBox(
                  label: 'W',
                  value:
                      position.width,
                  onChanged:
                      (value) {
                    _updatePhotoPosition(
                      index,
                      width: value,
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child:
                    _smallValueBox(
                  label: 'H',
                  value:
                      position.height,
                  onChanged:
                      (value) {
                    _updatePhotoPosition(
                      index,
                      height: value,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              const Text(
                'Rotation',
                style:
                    TextStyle(
                  color:
                      _textSecondary,
                  fontSize: 9,
                ),
              ),
              Expanded(
                child: Slider(
                  min: -180,
                  max: 180,
                  value: position
                      .rotation
                      .clamp(
                        -180,
                        180,
                      ),
                  onChanged:
                      _rotateSelected,
                ),
              ),
              SizedBox(
                width: 35,
                child: Text(
                  '${position.rotation.round()}°',
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    fontSize: 9,
                    color:
                        _textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL VALUE BOX
  // ============================================================

  Widget _smallValueBox({
    required String label,
    required double value,
    required ValueChanged<
            double>
        onChanged,
  }) {
    final controller =
        TextEditingController(
      text: value
          .round()
          .toString(),
    );

    return Row(
      children: [
        Container(
          width: 17,
          alignment:
              Alignment.center,
          child: Text(
            label,
            style:
                const TextStyle(
              color:
                  _textSecondary,
              fontSize: 9,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Expanded(
          child: TextBox(
            controller:
                controller,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            onSubmitted:
                (text) {
              final parsed =
                  double.tryParse(
                text,
              );

              if (parsed != null) {
                onChanged(
                  parsed,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return ContentDialog(
      constraints:
          const BoxConstraints(
        maxWidth: 1250,
        maxHeight: 850,
      ),
      style:
          ContentDialogThemeData(
        barrierColor:
            Colors.black
                .withAlpha(30),
      ),

      // ========================================================
      // TITLE
      // ========================================================

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: _green
                  .withAlpha(25),
              borderRadius:
                  BorderRadius
                      .circular(
                12,
              ),
            ),
            child: const Icon(
              LucideIcons.layout,
              size: 20,
              color: _green,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Create New Template',
                  style:
                      TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Design your photo booth layout visually',
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ========================================================
      // CONTENT
      // ========================================================

      content: SizedBox(
        width: 1200,
        height: 670,
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            // ====================================================
            // LEFT PANEL
            // ====================================================

            SizedBox(
              width: 300,
              child:
                  SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _sectionTitle(
                      icon:
                          FluentIcons
                              .edit,
                      title:
                          'Template Information',
                      subtitle:
                          'Configure your canvas.',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _card(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Template Name',
                            style:
                                TextStyle(
                              fontSize:
                                  11,
                              color:
                                  _textSecondary,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          TextBox(
                            controller:
                                _nameController,
                            placeholder:
                                'Wedding Gold',
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          const Text(
                            'Canvas Size',
                            style:
                                TextStyle(
                              fontSize:
                                  11,
                              color:
                                  _textSecondary,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          Row(
                            children: [
                              _numberField(
                                label:
                                    'Width',
                                controller:
                                    _widthController,
                                onChanged:
                                    () {
                                  setState(
                                    () {},
                                  );
                                },
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              _numberField(
                                label:
                                    'Height',
                                controller:
                                    _heightController,
                                onChanged:
                                    () {
                                  setState(
                                    () {},
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          const Text(
                            'Photo Slots',
                            style:
                                TextStyle(
                              fontSize:
                                  11,
                              color:
                                  _textSecondary,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _photoCountSelector(),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    Button(
                                  onPressed:
                                      _addPhotoSlot,
                                  child:
                                      const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        FluentIcons
                                            .add,
                                        size:
                                            12,
                                      ),
                                      SizedBox(
                                        width:
                                            5,
                                      ),
                                      Text(
                                        'Add Slot',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Button(
                                onPressed:
                                    _resetLayout,
                                child:
                                    const Icon(
                                  FluentIcons
                                      .reset,
                                  size:
                                      12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _sectionTitle(
                      icon:
                          FluentIcons
                              .picture,
                      title:
                          'Template Assets',
                      subtitle:
                          'Background and foreground.',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _imagePicker(
                      title:
                          'Background',
                      description:
                          'Behind photos',
                      filePath:
                          _backgroundPath,
                      onPressed:
                          _pickBackground,
                      icon:
                          FluentIcons
                              .picture,
                      requiredFile:
                          true,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _imagePicker(
                      title:
                          'Foreground',
                      description:
                          'Above photos',
                      filePath:
                          _foregroundPath,
                      onPressed:
                          _pickForeground,
                      icon:
                          LucideIcons
                              .layers,
                      requiredFile:
                          false,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildSelectedSlotPanel(),
                  ],
                ),
              ),
            ),

            const SizedBox(
              width: 18,
            ),

            // ====================================================
            // RIGHT PREVIEW
            // ====================================================

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  _sectionTitle(
                    icon:
                        FluentIcons
                            .preview,
                    title:
                        'Layout Preview',
                    subtitle:
                        'Drag slots to position them. Drag the corner to resize.',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Expanded(
                    child:
                        Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF050505,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color:
                              _border,
                        ),
                      ),
                      child:
                          LayoutBuilder(
                        builder:
                            (
                          context,
                          constraints,
                        ) {
                          return _buildCanvasPreview(
                            constraints,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      const Icon(
                        FluentIcons
                            .info,
                        size: 12,
                        color:
                            _textSecondary,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          'Canvas: ${_canvasWidth.round()} × ${_canvasHeight.round()} px  •  ${_photoPositions.length} photo slots',
                          style:
                              const TextStyle(
                            color:
                                _textSecondary,
                            fontSize:
                                9,
                          ),
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

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: [
        Button(
          onPressed:
              _isSaving
                  ? null
                  : () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
          child:
              const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            child:
                Text('Cancel'),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        FilledButton(
          onPressed:
              _isSaving
                  ? null
                  : _createTemplate,
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: _isSaving
                ? const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      ProgressRing(
                        strokeWidth:
                            2,
                        activeColor:
                            Colors
                                .white,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Creating...',
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons
                            .check_mark,
                        size: 15,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        'Create Template',
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
