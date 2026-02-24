use std::{process::Command, thread::sleep, time::Duration};
use tracing::{info, warn, error};
use crate::config::Config;

/// Sets backlight brightness using the calculated ambient value
pub fn set_backlight(ambient: f64, config: &Config) {
    // Calculate brightness based on configuration
    let brightness = if ambient < config.brightness.min_ambient {
        config.brightness.min_brightness
    } else if ambient > config.brightness.max_ambient {
        config.brightness.max_brightness
    } else {
        // Use the appropriate multiplier based on ambient level
        let multiplier = if ambient < 10.0 {
            config.brightness.low_ambient_multiplier
        } else {
            config.brightness.high_ambient_multiplier
        };
        
        let calculated = ambient * multiplier;
        calculated.clamp(config.brightness.min_brightness, config.brightness.max_brightness)
    };
    
    info!("Setting brightness: ambient={}, calculated={}, clamped={}", ambient, brightness, brightness);
    
    // Use animated native backlight control instead of brightnessctl command
    if let Err(e) = set_backlight_native_animated(brightness, config) {
        error!("Failed to set backlight natively: {}", e);
        // Try fallback native method
        if let Err(e2) = set_backlight_native(brightness, config) {
            error!("Failed to set backlight with fallback native method: {}", e2);
            // Fallback to brightnessctl if native method fails
            set_backlight_fallback(brightness);
        }
    }
}

/// Sets backlight brightness using native filesystem access
fn set_backlight_native(brightness: f64, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    // Try to write directly to the backlight control files
    let backlight_path = format!("{}/brightness", config.brightness.backlight_path);
    let max_brightness_path = format!("{}/max_brightness", config.brightness.backlight_path);
    
    // Read max brightness to calculate percentage
    let max_brightness_content = std::fs::read_to_string(max_brightness_path)?;
    let max_brightness: u32 = max_brightness_content.trim().parse()?;
    
    // Calculate actual brightness value (0-100% range)
    let actual_brightness = (brightness * max_brightness as f64 / 100.0).round() as u32;
    
    // Write to brightness file
    std::fs::write(backlight_path, format!("{}", actual_brightness))?;
    
    info!("Successfully set backlight to {} ({}% of max {})", 
          actual_brightness, brightness, max_brightness);
    Ok(())
}

/// Fallback method using brightnessctl command
fn set_backlight_fallback(brightness: f64) {
    let cmd = "brightnessctl";
    
    // Execute brightnessctl with args set and bright
    match Command::new(cmd)
        .args(["set", format!("{}%", brightness).as_str()])
        .output() {
        Ok(output) => {
            info!("Command executed successfully");
            info!("stdout: {}", String::from_utf8_lossy(&output.stdout));
            if !output.stderr.is_empty() {
                warn!("stderr: {}", String::from_utf8_lossy(&output.stderr));
            }
            info!("Exit status: {}", output.status);
        }
        Err(e) => {
            error!("Failed to execute fallback command: {}", e);
        }
    }
}

/// Sets backlight brightness with smooth animation
fn set_backlight_native_animated(target_brightness: f64, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    // Try to write directly to the backlight control files
    let backlight_path = format!("{}/brightness", config.brightness.backlight_path);
    let max_brightness_path = format!("{}/max_brightness", config.brightness.backlight_path);
    
    // Read max brightness to calculate percentage
    let max_brightness_content = std::fs::read_to_string(max_brightness_path)?;
    let max_brightness: u32 = max_brightness_content.trim().parse()?;
    
    // Calculate target actual brightness value
    let target_actual_brightness = (target_brightness * max_brightness as f64 / 100.0).round() as u32;
    
    // Read current brightness
    let current_brightness_content = std::fs::read_to_string(&backlight_path)?;
    let current_actual_brightness: u32 = current_brightness_content.trim().parse()?;
    
    // Calculate animation parameters
    let duration = Duration::from_millis(config.brightness.animation_duration_ms);
    let steps = config.brightness.animation_steps;
    let step_duration = duration / steps;
    
    // Calculate step size
    let step_size = if target_actual_brightness > current_actual_brightness {
        ((target_actual_brightness - current_actual_brightness) as f64 / steps as f64).ceil() as u32
    } else {
        ((current_actual_brightness - target_actual_brightness) as f64 / steps as f64).ceil() as u32
    };
    
    info!("Animating brightness from {} to {} in {} steps", 
          current_actual_brightness, target_actual_brightness, steps);
    
    // Animate brightness change
    let mut current = current_actual_brightness;
    let mut remaining_steps = steps;
    
    while remaining_steps > 0 && current != target_actual_brightness {
        // Calculate next brightness value
        if target_actual_brightness > current {
            current = (current + step_size).min(target_actual_brightness);
        } else {
            current = current.saturating_sub(step_size).max(target_actual_brightness);
        }
        
        // Write to brightness file
        std::fs::write(&backlight_path, format!("{}", current))?;
        
        // Wait for next step
        sleep(step_duration);
        remaining_steps -= 1;
    }
    
    // Ensure we reach the exact target value
    if current != target_actual_brightness {
        std::fs::write(&backlight_path, format!("{}", target_actual_brightness))?;
    }
    
    info!("Successfully animated backlight to {} ({}% of max {})", 
          target_actual_brightness, target_brightness, max_brightness);
    Ok(())
}

/// Gets current brightness level from the system
pub fn get_current_brightness(config: &Config) -> Result<f64, Box<dyn std::error::Error>> {
    let backlight_path = format!("{}/brightness", config.brightness.backlight_path);
    let max_brightness_path = format!("{}/max_brightness", config.brightness.backlight_path);
    
    // Read current brightness
    let current_brightness_content = std::fs::read_to_string(&backlight_path)?;
    let current_actual_brightness: u32 = current_brightness_content.trim().parse()?;
    
    // Read max brightness
    let max_brightness_content = std::fs::read_to_string(max_brightness_path)?;
    let max_brightness: u32 = max_brightness_content.trim().parse()?;
    
    // Calculate percentage
    let current_brightness = (current_actual_brightness as f64 / max_brightness as f64) * 100.0;
    
    Ok(current_brightness)
}