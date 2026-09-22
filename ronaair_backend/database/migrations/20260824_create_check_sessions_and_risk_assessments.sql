-- ============================================================================
-- Migration: Create check_sessions and risk_assessments tables
--          Add visual_score column to visual_analyses
-- ============================================================================

-- Add visual_score column to visual_analyses table
ALTER TABLE visual_analyses ADD COLUMN IF NOT EXISTS visual_score DECIMAL(5,2) NULL AFTER confidence;
ALTER TABLE visual_analyses ADD COLUMN IF NOT EXISTS visual_score_unit VARCHAR(20) NULL AFTER visual_score;
ALTER TABLE visual_analyses ADD COLUMN IF NOT EXISTS model_version VARCHAR(50) NULL AFTER visual_score_unit;
ALTER TABLE visual_analyses ADD COLUMN IF NOT EXISTS data_quality VARCHAR(30) NULL AFTER model_version;

-- Create check_sessions table for one examination session
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

-- Create risk_assessments table for risk assessment results
CREATE TABLE IF NOT EXISTS risk_assessments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  check_session_id BIGINT UNSIGNED NOT NULL UNIQUE,
  risk_level VARCHAR(20) NOT NULL,
  factors JSON NULL,
  explanation TEXT NULL,
  recommendation TEXT NULL,
  assessed_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  model_version VARCHAR(50) NULL,
  data_quality VARCHAR(30) NULL,
  FOREIGN KEY (check_session_id) REFERENCES check_sessions(id) ON DELETE CASCADE,
  INDEX idx_risk_level (risk_level),
  INDEX idx_risk_time (assessed_at)
);