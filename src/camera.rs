use nokhwa::{Camera, utils::{CameraIndex, RequestedFormat, RequestedFormatType}, pixel_format::RgbFormat};
use tracing::{error, debug};
use std::thread::sleep;
use std::time::Duration;
use crate::config::Config;

/// Captures camera frame and calculates luminosity
pub fn get_luminosity(config: &Config) -> f64 {
    // Open the camera specified in configuration
    let index = CameraIndex::Index(config.camera.device_index);
    let requested = RequestedFormat::new::<RgbFormat>(RequestedFormatType::AbsoluteHighestFrameRate);
    
    let mut camera = match Camera::new(index, requested) {
        Ok(camera) => camera,
        Err(e) => {
            error!("Failed to open camera: {}", e);
            return 40.0; // Fallback to medium luminosity
        }
    };

    // Start the camera stream
    if let Err(e) = camera.open_stream() {
        error!("Failed to start camera stream: {}", e);
        return 40.0; // Fallback to medium luminosity
    }

    // Capture a single frame
    let frame = match camera.frame() {
        Ok(frame) => frame,
        Err(e) => {
            error!("Failed to capture frame: {}", e);
            return 40.0; // Fallback to medium luminosity
        }
    };
    
    let decoded = match frame.decode_image::<RgbFormat>() {
        Ok(decoded) => decoded,
        Err(e) => {
            error!("Failed to decode frame: {}", e);
            return 40.0; // Fallback to medium luminosity
        }
    };

    // Compute luminosity (average brightness)
    let luminosity: f64 = decoded
        .pixels()
        .map(|pixel| {
            // Convert RGB to luminance using standard weights: 0.299R + 0.587G + 0.114B
            0.299 * (pixel[0] as f64) + 0.587 * (pixel[1] as f64) + 0.114 * (pixel[2] as f64)
        })
        .sum::<f64>() / decoded.len() as f64;

    debug!("Average luminosity: {}", luminosity);
    
    // Apply capture delay if configured
    if config.camera.capture_delay_ms > 0 {
        sleep(Duration::from_millis(config.camera.capture_delay_ms));
    }
    
    luminosity
}