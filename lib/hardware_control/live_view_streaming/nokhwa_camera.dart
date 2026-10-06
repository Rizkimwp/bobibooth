import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/src/rust/api/nokhwa.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/nokhwa.dart';
import 'package:momento_booth/src/rust/models/image_operations.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';

class NokhwaCamera extends LiveViewSource {
  @override
  final String id;

  @override
  final String friendlyName;

  int? handleId;

  static Future<void>? _initFuture;

  NokhwaCamera({required this.id, required this.friendlyName});

  static NokhwaCamera fromCameraInfo(NokhwaCameraInfo info) {
    return NokhwaCamera(
      id: info.friendlyName,
      friendlyName: info.friendlyName,
    );
  }

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<NokhwaCameraInfo>> listCameras() async {
    await _ensureLibraryInitialized();

    return await nokhwaGetCameras();
  }

  static Future<List<NokhwaCamera>> getAllCameras() async {
    return (await listCameras()).map(NokhwaCamera.fromCameraInfo).toList();
  }

  static Future<List<ComboBoxItem<String>>> getCamerasAsComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

  ComboBoxItem<String> toComboBoxItem() =>
      ComboBoxItem(value: id, child: Text(friendlyName));

  // ////////////// //
  // Control camera //
  // ////////////// //

  @override
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [],
  }) async {
    await _ensureLibraryInitialized();

    handleId = await nokhwaOpenCamera(
      friendlyName: friendlyName,
      operations: operations,
      texturePtr: texturePtr,
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) async {
    final handle = handleId;

    if (handle == null) {
      return;
    }

    await nokhwaSetOperations(handleId: handle, operations: operations);
  }

  @override
  Future<RawImage?> getLastFrame() async {
    final handle = handleId;

    if (handle == null) {
      return null;
    }

    return await nokhwaGetLastFrame(handleId: handle);
  }

  @override
  Future<CameraState> getCameraState() async {
    final handle = handleId;

    if (handle == null) {
      // Sesuaikan dengan enum CameraState yang tersedia
      throw StateError('Camera has not been opened');
    }

    return await nokhwaGetCameraStatus(handleId: handle);
  }

  @override
  Future<void> dispose() async {
    final handle = handleId;

    // Kamera belum pernah berhasil dibuka.
    if (handle == null) {
      return;
    }

    try {
      await nokhwaCloseCamera(handleId: handle);
    } finally {
      handleId = null;
    }
  }

  static Future<void> _ensureLibraryInitialized() async {
    _initFuture ??= nokhwaInitialize();

    await _initFuture;
  }
}
