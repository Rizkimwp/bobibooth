use std::{
    sync::{
        atomic::{AtomicBool, AtomicU32, Ordering},
        Arc, LazyLock, Mutex,
    },
    time::Instant,
};

use chrono::Duration;
use dashmap::DashMap;
use log::{debug, error, info};

use nokhwa::{
    native_api_backend,
    pixel_format::RgbAFormat,
    query,
    utils::{
        CameraInfo,
        FrameFormat,
        RequestedFormat,
        RequestedFormatType,
    },
    CallbackCamera,
};

use crate::{
    frb_generated::StreamSink,
    models::{
        image_operations::ImageOperation,
        images::RawImage,
        live_view::CameraState,
    },
    utils::{
        flutter_texture::FlutterTexture,
        image_processing,
        jpeg,
    },
};

// ============================================================
// Camera Discovery
// ============================================================

pub fn get_cameras() -> Vec<NokhwaCameraInfo> {
    let backend = native_api_backend()
        .expect("Could not get Nokhwa backend");

    let devices = query(backend)
        .expect("Could not query cameras");

    info!(
        "Nokhwa discovered {} camera device(s)",
        devices.len()
    );

    devices
        .iter()
        .map(|camera| {
            info!(
                "Camera discovery: name='{}', index={:?}",
                camera.human_name(),
                camera.index()
            );

            NokhwaCameraInfo::from_camera_info(camera)
        })
        .collect()
}

// ============================================================
// Camera Open
// ============================================================

pub fn open_camera<F>(
    friendly_name: String,
    frame_callback: F,
) -> CallbackCamera
where
    F: Fn(Option<RawImage>) + Send + Sync + 'static,
{
    debug!(
        "nokhwa::open_camera() opening '{}'",
        &friendly_name
    );

    // ============================================================
    // 1. Query cameras
    // ============================================================

    let backend = native_api_backend()
        .expect("Could not get Nokhwa backend");

    let devices = query(backend)
        .expect("Could not query cameras");

    info!(
        "Nokhwa found {} camera(s)",
        devices.len()
    );

    for device in &devices {
        info!(
            "Camera: name='{}', index={:?}",
            device.human_name(),
            device.index()
        );
    }

    // ============================================================
    // 2. Cari semua device dengan nama yang sama
    //
    // Linux dapat memiliki lebih dari satu video node dengan
    // human_name yang sama.
    //
    // Contoh di mesin:
    //
    // Index(1) -> Integrated Camera
    // Index(0) -> Integrated Camera
    //
    // Index(1) dapat merupakan metadata node.
    //
    // Kita prioritaskan index terkecil.
    // ============================================================

    let mut matching_devices = devices
        .into_iter()
        .filter(|device| device.human_name() == friendly_name)
        .collect::<Vec<_>>();

    if matching_devices.is_empty() {
        panic!(
            "Could not find camera '{}'",
            friendly_name
        );
    }

    // ============================================================
    // 3. Sort berdasarkan camera index
    // ============================================================

    matching_devices.sort_by_key(|device| {
        device
            .index()
            .as_index()
            .unwrap_or(u32::MAX)
    });

    info!(
        "Found {} camera device(s) matching '{}'",
        matching_devices.len(),
        friendly_name
    );

    for device in &matching_devices {
        info!(
            "Matching camera: name='{}', index={:?}",
            device.human_name(),
            device.index()
        );
    }

    // ============================================================
    // 4. Pilih device dengan index terkecil
    // ============================================================

    let camera_info = matching_devices
        .into_iter()
        .next()
        .expect("No matching camera device");

    info!(
        "Selected camera: '{}' index={:?}",
        camera_info.human_name(),
        camera_info.index()
    );

    // ============================================================
    // 5. Requested format
    //
    // Jangan hard-code:
    //
    // 640x480 MJPEG
    // 1280x720 MJPEG
    //
    // Kita biarkan Nokhwa memilih format terbaik yang didukung
    // oleh RgbAFormat.
    // ============================================================

    let format = RequestedFormat::new::<RgbAFormat>(
        RequestedFormatType::AbsoluteHighestResolution,
    );

    info!(
        "Requested format: AbsoluteHighestResolution / RgbAFormat"
    );

    // ============================================================
    // 6. Buat CallbackCamera
    // ============================================================

    info!(
        "Creating CallbackCamera: name='{}', index={:?}",
        friendly_name,
        camera_info.index()
    );

    let camera = CallbackCamera::new(
        camera_info.index().clone(),
        format,
        move |buffer| {
            // ====================================================
            // Frame information
            // ====================================================

            let source_format =
                buffer.source_frame_format();

            let width =
                buffer.resolution().width();

            let height =
                buffer.resolution().height();

            debug!(
                "Received frame: format={:?}, resolution={}x{}, bytes={}",
                source_format,
                width,
                height,
                buffer.buffer().len()
            );

            // ====================================================
            // MJPEG
            // ====================================================

            if source_format == FrameFormat::MJPEG {
                let raw_image =
                    jpeg::decode_jpeg_to_rgba(
                        buffer.buffer()
                    );

                frame_callback(Some(raw_image));

                return;
            }

            // ====================================================
            // Format lainnya
            //
            // Decode menggunakan Nokhwa -> RGBA
            // ====================================================

            match buffer.decode_image::<RgbAFormat>() {
                Ok(image_buffer) => {
                    let raw_image =
                        RawImage::new_from_rgba_data(
                            image_buffer.into_vec(),
                            width as u32,
                            height as u32,
                        );

                    frame_callback(Some(raw_image));
                }

                Err(error) => {
                    error!(
                        "Image decoding error: format={:?}, resolution={}x{}, error={}",
                        source_format,
                        width,
                        height,
                        error
                    );

                    frame_callback(None);
                }
            }
        },
    )
    .unwrap_or_else(|error| {
        panic!(
            "Could not create CallbackCamera '{}' index {:?}: {:?}",
            friendly_name,
            camera_info.index(),
            error
        );
    });

    info!(
        "CallbackCamera created successfully: '{}' index={:?}",
        friendly_name,
        camera_info.index()
    );

    // ============================================================
    // PENTING:
    //
    // Jangan open_stream() di sini.
    //
    // Handle harus dimasukkan ke NOKHWA_HANDLES terlebih dahulu.
    //
    // open_stream() dilakukan setelah nokhwa_open_camera()
    // memasukkan handle.
    // ============================================================

    camera
}

// ============================================================
// Camera Close
// ============================================================

pub fn close_camera(camera: &mut CallbackCamera) {
    if let Err(error) = camera.set_callback(|_| {}) {
        error!(
            "Cannot set callback to dummy callback: {:?}",
            error
        );
    }
}

// ============================================================
// Camera Info
// ============================================================

pub struct NokhwaCameraInfo {
    pub id: u32,
    pub friendly_name: String,
}

impl NokhwaCameraInfo {
    pub fn from_camera_info(
        camera_info: &CameraInfo,
    ) -> Self {
        Self {
            id: camera_info
                .index()
                .as_index()
                .expect("Could not get camera index"),

            friendly_name: camera_info.human_name(),
        }
    }
}

// ============================================================
// Nokhwa Global State
// ============================================================

pub static NOKHWA_HANDLES: LazyLock<
    DashMap<u32, Arc<Mutex<NokhwaCameraHandle>>>,
> = LazyLock::new(|| DashMap::new());

static NOKHWA_HANDLE_COUNT: AtomicU32 =
    AtomicU32::new(1);

static NOKHWA_INITIALIZED: AtomicBool =
    AtomicBool::new(false);

// ============================================================
// Nokhwa Initialization
// ============================================================

pub async fn initialize_nokhwa() -> bool {
    let (future, handle) = susync::create();

    if !NOKHWA_INITIALIZED.load(Ordering::SeqCst) {
        // ----------------------------------------------------
        // First initialization
        // ----------------------------------------------------

        nokhwa::nokhwa_initialize(move |success| {
            debug!(
                "initialize_hardware() nokhwa init result: {}",
                success
            );

            handle.clone().complete(success);
        });

        NOKHWA_INITIALIZED.store(
            true,
            Ordering::SeqCst,
        );

        info!("Initialized Nokhwa");
    } else {
        // ----------------------------------------------------
        // Hot reload
        // ----------------------------------------------------

        debug!(
            "Possible Hot Reload: Closing open Nokhwa handles"
        );

        for map_entry in NOKHWA_HANDLES.iter() {
            if let Ok(mut handle) =
                map_entry.value().lock()
            {
                if let Err(error) =
                    handle.camera.set_callback(|_| {})
                {
                    error!(
                        "Error closing Nokhwa handle: {:?}",
                        error
                    );
                }
            }
        }

        debug!(
            "Possible Hot Reload: Closed Nokhwa handles"
        );

        NOKHWA_HANDLES.clear();

        handle.complete(true);
    }

    future.await.unwrap_or(false)
}

// ============================================================
// FRB API - Get Cameras
// ============================================================

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    get_cameras()
}

// ============================================================
// FRB API - Open Camera
// ============================================================

pub fn nokhwa_open_camera(
    friendly_name: String,
    operations: Vec<ImageOperation>,
    texture_ptr: usize,
) -> u32 {
    // ============================================================
    // 1. Create Flutter texture
    // ============================================================

    let renderer =
        FlutterTexture::new(
            texture_ptr,
            0,
            0,
        );

    let renderer_mutex =
        Arc::new(Mutex::new(renderer));

    // ============================================================
    // 2. Generate handle ID
    // ============================================================

    let handle_id =
        NOKHWA_HANDLE_COUNT.fetch_add(
            1,
            Ordering::SeqCst,
        );

    info!(
        "Opening Nokhwa camera '{}' with handle {}",
        friendly_name,
        handle_id
    );

    // ============================================================
    // 3. Clone renderer untuk callback
    // ============================================================

    let renderer_callback =
        Arc::clone(&renderer_mutex);

    // ============================================================
    // 4. Create CallbackCamera
    //
    // Belum open_stream().
    // ============================================================

    let camera = open_camera(
        friendly_name.clone(),
        move |raw_frame| {
            // ====================================================
            // Cari handle
            // ====================================================

            let camera_ref =
                match NOKHWA_HANDLES.get(&handle_id) {
                    Some(camera_ref) => camera_ref,

                    None => {
                        error!(
                            "Nokhwa callback received before handle {} was available",
                            handle_id
                        );

                        return;
                    }
                };

            let mut handle =
                match camera_ref.lock() {
                    Ok(handle) => handle,

                    Err(error) => {
                        error!(
                            "Could not lock Nokhwa handle {}: {:?}",
                            handle_id,
                            error
                        );

                        return;
                    }
                };

            // ====================================================
            // Process frame
            // ====================================================

            match raw_frame {
                Some(raw_frame) => {
                    // ------------------------------------------------
                    // Apply image operations
                    // ------------------------------------------------

                    let processed_frame =
                        image_processing::execute_operations(
                            &raw_frame,
                            &handle.operations,
                        );

                    // ------------------------------------------------
                    // Update Flutter texture
                    // ------------------------------------------------

                    let mut renderer =
                        match renderer_callback.lock() {
                            Ok(renderer) => renderer,

                            Err(error) => {
                                error!(
                                    "Could not lock renderer: {:?}",
                                    error
                                );

                                return;
                            }
                        };

                    renderer.set_size(
                        processed_frame.width,
                        processed_frame.height,
                    );

                    renderer.on_rgba(
                        &processed_frame,
                    );

                    // ------------------------------------------------
                    // Update camera state
                    // ------------------------------------------------

                    handle
                        .valid_frame_count
                        .fetch_add(
                            1,
                            Ordering::SeqCst,
                        );

                    handle
                        .last_frame_was_valid
                        .store(
                            true,
                            Ordering::SeqCst,
                        );

                    handle.last_valid_frame =
                        Some(processed_frame);
                }

                None => {
                    handle
                        .error_frame_count
                        .fetch_add(
                            1,
                            Ordering::SeqCst,
                        );

                    handle
                        .last_frame_was_valid
                        .store(
                            false,
                            Ordering::SeqCst,
                        );
                }
            }

            handle.last_received_frame_timestamp =
                Some(Instant::now());
        },
    );

    // ============================================================
    // 5. Insert handle BEFORE open_stream()
    //
    // Ini penting untuk mencegah race condition callback.
    // ============================================================

    NOKHWA_HANDLES.insert(
        handle_id,
        Arc::new(
            Mutex::new(
                NokhwaCameraHandle::new(
                    camera,
                    operations,
                ),
            ),
        ),
    );

    info!(
        "Nokhwa handle {} inserted",
        handle_id
    );

    // ============================================================
    // 6. Open stream setelah handle tersedia
    // ============================================================

    let camera_ref =
        NOKHWA_HANDLES
            .get(&handle_id)
            .expect("Invalid Nokhwa handle ID");

    let mut handle =
        camera_ref
            .lock()
            .expect(
                "Could not lock Nokhwa handle",
            );

    handle
        .camera
        .open_stream()
        .unwrap_or_else(|error| {
            panic!(
                "Could not open camera stream '{}': {:?}",
                friendly_name,
                error
            );
        });

    info!(
        "Camera stream opened successfully for '{}' handle={}",
        friendly_name,
        handle_id
    );

    // ============================================================
    // 7. Log actual camera format
    // ============================================================

    match handle.camera.camera_format() {
        Ok(camera_format) => {
            info!(
                "nokhwa::open_camera() opened '{}' handle={} ({})",
                friendly_name,
                handle_id,
                camera_format
            );
        }

        Err(error) => {
            error!(
                "Could not get camera format for '{}' handle={}: {:?}",
                friendly_name,
                handle_id,
                error
            );
        }
    }

    // ============================================================
    // 8. Return handle
    // ============================================================

    handle_id
}

// ============================================================
// FRB API - Set Operations
// ============================================================

pub fn nokhwa_set_operations(
    handle_id: u32,
    operations: Vec<ImageOperation>,
) {
    let camera_ref =
        NOKHWA_HANDLES
            .get(&handle_id)
            .expect(
                "Invalid Nokhwa handle ID",
            );

    let mut handle =
        camera_ref
            .lock()
            .expect(
                "Could not lock Nokhwa handle",
            );

    handle.operations = operations;
}

// ============================================================
// FRB API - Camera Status
// ============================================================

pub fn nokhwa_get_camera_status(
    handle_id: u32,
) -> CameraState {
    let camera_ref =
        NOKHWA_HANDLES
            .get(&handle_id)
            .expect(
                "Invalid Nokhwa handle ID",
            );

    let handle =
        camera_ref
            .lock()
            .expect(
                "Could not lock Nokhwa handle",
            );

    CameraState {
        is_streaming: true,

        valid_frame_count:
            handle
                .valid_frame_count
                .load(Ordering::SeqCst),

        error_frame_count:
            handle
                .error_frame_count
                .load(Ordering::SeqCst),

        duplicate_frame_count: 0,

        last_frame_was_valid:
            handle
                .last_frame_was_valid
                .load(Ordering::SeqCst),

        time_since_last_received_frame:
            handle
                .last_received_frame_timestamp
                .map(|timestamp| {
                    Duration::from_std(
                        timestamp.elapsed(),
                    )
                    .expect(
                        "Could not convert duration",
                    )
                }),

        frame_width:
            handle
                .last_valid_frame
                .as_ref()
                .map(|frame| frame.width),

        frame_height:
            handle
                .last_valid_frame
                .as_ref()
                .map(|frame| frame.height),
    }
}

// ============================================================
// FRB API - Last Frame
// ============================================================

pub fn nokhwa_get_last_frame(
    handle_id: u32,
) -> Option<RawImage> {
    let entry =
        NOKHWA_HANDLES
            .get(&handle_id)
            .expect(
                "Invalid Nokhwa handle ID",
            );

    let handle =
        entry
            .lock()
            .expect(
                "Could not lock Nokhwa handle",
            );

    handle.last_valid_frame.clone()
}

// ============================================================
// FRB API - Close Camera
// ============================================================

pub fn nokhwa_close_camera(
    handle_id: u32,
) {
    let (_, handle) =
        NOKHWA_HANDLES
            .remove(&handle_id)
            .expect(
                "Invalid Nokhwa handle ID",
            );

    let mut handle =
        handle
            .lock()
            .expect(
                "Could not lock Nokhwa handle",
            );

    close_camera(
        &mut handle.camera
    );
}

// ============================================================
// Camera Handle
// ============================================================

pub struct NokhwaCameraHandle {
    pub status_sink:
        Option<StreamSink<CameraState>>,

    pub camera:
        CallbackCamera,

    pub valid_frame_count:
        AtomicU32,

    pub error_frame_count:
        AtomicU32,

    pub last_frame_was_valid:
        AtomicBool,

    pub last_valid_frame:
        Option<RawImage>,

    pub last_received_frame_timestamp:
        Option<Instant>,

    pub operations:
        Vec<ImageOperation>,
}

// ============================================================
// Camera Handle Constructor
// ============================================================

impl NokhwaCameraHandle {
    fn new(
        camera: CallbackCamera,
        operations: Vec<ImageOperation>,
    ) -> Self {
        Self {
            status_sink: None,

            camera,

            valid_frame_count:
                AtomicU32::new(0),

            error_frame_count:
                AtomicU32::new(0),

            last_frame_was_valid:
                AtomicBool::new(false),

            last_valid_frame:
                None,

            last_received_frame_timestamp:
                None,

            operations,
        }
    }
}

// ============================================================
// Drop
// ============================================================

impl Drop for NokhwaCameraHandle {
    fn drop(&mut self) {
        debug!(
            "Dropping NokhwaCameraHandle"
        );
    }
}