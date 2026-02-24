use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use std::env;

#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    pub brightness: BrightnessConfig,
    pub camera: CameraConfig,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CameraConfig {
    pub capture_delay_ms: u64,
    pub device_index: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct BrightnessConfig {
    pub min_ambient: f64,
    pub max_ambient: f64,
    pub min_brightness: f64,
    pub max_brightness: f64,
    pub low_ambient_multiplier: f64,
    pub high_ambient_multiplier: f64,
    pub animation_duration_ms: u64,
    pub animation_steps: u32,
    pub backlight_path: String,
    pub brightness_threshold: f64,
}

impl Default for BrightnessConfig {
    fn default() -> Self {
        Self {
            min_ambient: 0.0,
            max_ambient: 100.0,
            min_brightness: 0.0,
            max_brightness: 100.0,
            low_ambient_multiplier: 0.5,
            high_ambient_multiplier: 1.5,
            animation_duration_ms: 500,
            animation_steps: 20,
            backlight_path: "/sys/class/backlight/intel_backlight".to_string(),
            brightness_threshold: 5.0,
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            brightness: BrightnessConfig::default(),
            camera: CameraConfig::default(),
        }
    }
}

impl Default for CameraConfig {
    fn default() -> Self {
        Self {
            capture_delay_ms: 100,
            device_index: 0,
        }
    }
}

impl Config {
    pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
        // Define search paths in order of preference
        let search_paths = Self::get_config_search_paths();
        
        // Try each path until we find a valid config file
        for path in search_paths {
            if path.exists() {
                match Self::load_from_path(&path) {
                    Ok(config) => {
                        println!("Loaded configuration from: {}", path.display());
                        return Ok(config);
                    }
                    Err(e) => {
                        eprintln!("Failed to load config from {}: {}", path.display(), e);
                        continue;
                    }
                }
            }
        }
        
        // If no config file found, return default config
        println!("No configuration file found, using defaults");
        Ok(Config::default())
    }

    pub fn load_from_path<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = fs::read_to_string(path)?;
        let config: Config = toml::from_str(&content)?;
        Ok(config)
    }

    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), Box<dyn std::error::Error>> {
        let content = toml::to_string_pretty(self)?;
        fs::write(path, content)?;
        Ok(())
    }

    fn get_config_search_paths() -> Vec<PathBuf> {
        let mut paths = Vec::new();
        
        // 1. User config directory: ~/.config/lumasense/config.toml
        if let Some(home_dir) = dirs::config_dir() {
            let user_config_path = home_dir.join("lumasense").join("config.toml");
            paths.push(user_config_path);
        }
        
        // 2. System config: /etc/lumasense.conf
        paths.push(PathBuf::from("/etc/lumasense.conf"));
        
        // 3. Executable directory: config.toml
        if let Ok(exe_path) = env::current_exe() {
            if let Some(exe_dir) = exe_path.parent() {
                paths.push(exe_dir.join("config.toml"));
            }
        }
        
        paths
    }
}
