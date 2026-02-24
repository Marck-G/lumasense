use std::time::Duration;
use tracing::{info, error, debug};
use tracing_subscriber;
use lumasense::{Config, get_luminosity, set_backlight};

fn main() {
    // Initialize tracing subscriber for professional logging
    tracing_subscriber::fmt::SubscriberBuilder::default().with_ansi(false).compact().init();
    
    // Load configuration with polling
    let config = match Config::load() {
        Ok(c) => c,
        Err(e) => {
            error!("Failed to load any configuration file, using defaults: {}", e);
            Config::default()
        }
    };
    
    let mut last_brightness = 0.0;
    
    loop {
        let ambient = get_luminosity(&config);
        info!("Ambient light level: {}", ambient);
        
        // Calculate target brightness
        let target_brightness = if ambient < config.brightness.min_ambient {
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
        
        // Only update if the difference is greater than the threshold
        let brightness_diff = (target_brightness - last_brightness).abs();
        if brightness_diff >= config.brightness.brightness_threshold {
            info!("Brightness difference {} >= threshold {}, updating", brightness_diff, config.brightness.brightness_threshold);
            set_backlight(target_brightness, &config);
            last_brightness = target_brightness;
        } else {
            debug!("Brightness difference {} < threshold {}, skipping update", brightness_diff, config.brightness.brightness_threshold);
        }
        
        std::thread::sleep(Duration::from_secs(config.brightness.sleep_seconds));
    }
}
