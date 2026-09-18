-- ============================================
-- RonaAir Database Schema
-- ============================================

CREATE DATABASE IF NOT EXISTS ronaair
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ronaair;

-- ============================================
-- 1. PONDS
-- ============================================
CREATE TABLE IF NOT EXISTS ponds (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- 2. DEVICES
-- ============================================
CREATE TABLE IF NOT EXISTS devices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pond_id BIGINT UNSIGNED NOT NULL,
  device_code VARCHAR(50) NOT NULL UNIQUE,
  device_type VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'disconnected',
  last_seen TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE CASCADE
);

-- ============================================
-- 3. SENSOR READINGS
-- ============================================
CREATE TABLE IF NOT EXISTS sensor_readings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pond_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NULL,
  temperature DECIMAL(5,2) NULL,
  ph DECIMAL(4,2) NULL,
  turbidity DECIMAL(6,2) NULL,
  estimated_do DECIMAL(5,2) NULL,
  measured_do DECIMAL(5,2) NULL,
  ec_tds DECIMAL(8,2) NULL,
  recorded_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE CASCADE,
  FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE SET NULL,
  INDEX idx_sensor_pond_time (pond_id, recorded_at)
);

-- ============================================
-- 4. VISUAL ANALYSES
-- ============================================
CREATE TABLE IF NOT EXISTS visual_analyses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pond_id BIGINT UNSIGNED NOT NULL,
  image_path VARCHAR(255) NOT NULL,
  photo_type VARCHAR(20) DEFAULT 'water',
  quality_status VARCHAR(20) DEFAULT 'valid',
  quality_details JSON NULL,
  visual_indicator VARCHAR(50) NULL,
  confidence DECIMAL(5,4) NULL,
  model_version VARCHAR(50) NULL,
  analyzed_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE CASCADE,
  INDEX idx_visual_pond_time (pond_id, analyzed_at)
);

-- ============================================
-- 5. CHECK SESSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS check_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pond_id BIGINT UNSIGNED NOT NULL,
  sensor_reading_id BIGINT UNSIGNED NULL,
  visual_analysis_id BIGINT UNSIGNED NULL,
  started_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP NULL,
  status VARCHAR(20) DEFAULT 'in_progress',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE CASCADE,
  FOREIGN KEY (sensor_reading_id) REFERENCES sensor_readings(id) ON DELETE SET NULL,
  FOREIGN KEY (visual_analysis_id) REFERENCES visual_analyses(id) ON DELETE SET NULL,
  INDEX idx_check_pond_time (pond_id, started_at)
);

-- ============================================
-- 6. RISK ASSESSMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS risk_assessments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  check_session_id BIGINT UNSIGNED NOT NULL UNIQUE,
  risk_level VARCHAR(20) NOT NULL,
  factors JSON NULL,
  explanation TEXT NULL,
  recommendation TEXT NULL,
  assessed_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (check_session_id) REFERENCES check_sessions(id) ON DELETE CASCADE,
  INDEX idx_risk_level (risk_level),
  INDEX idx_risk_time (assessed_at)
);