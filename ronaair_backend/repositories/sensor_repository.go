package repositories

import (
	"context"
	"database/sql"
	"time"

	"github.com/ronaair/backend/models"
)

type SensorRepository struct {
	DB *sql.DB
}

func NewSensorRepository(db *sql.DB) *SensorRepository {
	return &SensorRepository{DB: db}
}

// Insert menyimpan pembacaan sensor baru.
func (r *SensorRepository) Insert(ctx context.Context, req models.SensorReadingRequest) (int64, error) {
	query := `
		INSERT INTO sensor_readings
			(pond_id, device_id, temperature, ph, turbidity,
			 estimated_do, measured_do, ec_tds, recorded_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`
	res, err := r.DB.ExecContext(ctx, query,
		req.PondID, req.DeviceID, req.Temperature, req.PH, req.Turbidity,
		req.EstimatedDO, req.MeasuredDO, req.ECTDS, time.Now(),
	)
	if err != nil {
		return 0, err
	}
	return res.LastInsertId()
}

// GetLatestByPond mengambil pembacaan terbaru untuk satu kolam.
func (r *SensorRepository) GetLatestByPond(ctx context.Context, pondID int64) (*models.SensorReading, error) {
	query := `
		SELECT id, pond_id, device_id, temperature, ph, turbidity,
		       estimated_do, measured_do, ec_tds, recorded_at, created_at
		FROM sensor_readings
		WHERE pond_id = ?
		ORDER BY recorded_at DESC
		LIMIT 1
	`
	row := r.DB.QueryRowContext(ctx, query, pondID)

	var s models.SensorReading
	err := row.Scan(
		&s.ID, &s.PondID, &s.DeviceID, &s.Temperature, &s.PH, &s.Turbidity,
		&s.EstimatedDO, &s.MeasuredDO, &s.ECTDS, &s.RecordedAt, &s.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}
