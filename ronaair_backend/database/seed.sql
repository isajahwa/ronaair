USE ronaair;

-- ============================================
-- Pond contoh
-- ============================================
INSERT INTO ponds (name, location)
VALUES ('Kolam A', 'Desa Sukamaju');

-- ============================================
-- Device contoh
-- ============================================
INSERT INTO devices (pond_id, device_code, device_type, status, last_seen)
VALUES (1, 'esp32-01', 'esp32', 'connected', NOW());

-- ============================================
-- Sensor readings contoh (3 data)
-- ============================================
INSERT INTO sensor_readings
  (pond_id, device_id, temperature, ph, turbidity, estimated_do, recorded_at)
VALUES
  (1, 1, 28.5, 7.2, 15.3, 6.1, NOW() - INTERVAL 2 HOUR),
  (1, 1, 27.8, 7.0, 12.1, 6.5, NOW() - INTERVAL 8 HOUR),
  (1, 1, 29.2, 6.8, 20.5, 5.4, NOW() - INTERVAL 1 DAY);

-- ============================================
-- Visual analyses contoh
-- ============================================
INSERT INTO visual_analyses
  (pond_id, image_path, photo_type, quality_status, visual_indicator, confidence, analyzed_at)
VALUES
  (1, '/mock/water_01.jpg', 'water', 'valid', 'waspada', 0.82, NOW() - INTERVAL 2 HOUR),
  (1, '/mock/water_02.jpg', 'water', 'valid', 'normal', 0.91, NOW() - INTERVAL 8 HOUR),
  (1, '/mock/water_03.jpg', 'water', 'valid', 'siaga', 0.78, NOW() - INTERVAL 1 DAY);

-- ============================================
-- Check sessions contoh
-- ============================================
INSERT INTO check_sessions
  (pond_id, sensor_reading_id, visual_analysis_id, started_at, completed_at, status)
VALUES
  (1, 1, 1, NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 2 HOUR, 'completed'),
  (1, 2, 2, NOW() - INTERVAL 8 HOUR, NOW() - INTERVAL 8 HOUR, 'completed'),
  (1, 3, 3, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, 'completed');

-- ============================================
-- Risk assessments contoh
-- ============================================
INSERT INTO risk_assessments
  (check_session_id, risk_level, factors, explanation, recommendation, assessed_at)
VALUES
  (1, 'WASPADA',
   JSON_ARRAY('Turbidity meningkat', 'pH sedikit menurun'),
   'Kondisi air menunjukkan perubahan yang perlu dipantau.',
   'Periksa kembali kondisi air dan pantau perubahan warna.',
   NOW() - INTERVAL 2 HOUR),
  (2, 'NORMAL',
   JSON_ARRAY('Semua parameter dalam rentang normal'),
   'Kondisi air stabil.',
   'Lanjutkan pemantauan rutin.',
   NOW() - INTERVAL 8 HOUR),
  (3, 'SIAGA',
   JSON_ARRAY('Turbidity tinggi', 'pH menurun'),
   'Kombinasi evidence menunjukkan peningkatan risiko.',
   'Lakukan pemeriksaan lanjutan dan konsultasi dengan penyuluh.',
   NOW() - INTERVAL 1 DAY);