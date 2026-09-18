package repositories

import (
	"context"
	"database/sql"

	"github.com/ronaair/backend/models"
)

type CheckSessionRepository struct {
	DB *sql.DB
}

func NewCheckSessionRepository(db *sql.DB) *CheckSessionRepository {
	return &CheckSessionRepository{DB: db}
}

// GetHistoryByPond mengambil riwayat pemeriksaan.
func (r *CheckSessionRepository) GetHistoryByPond(
	ctx context.Context, pondID int64, limit int,
) ([]models.HistoryItem, error) {

	query := `
		SELECT
			cs.id,
			COALESCE(ra.risk_level, 'NORMAL') AS risk_level,
			cs.started_at,
			sr.temperature,
			sr.ph,
			sr.turbidity,
			sr.estimated_do
		FROM check_sessions cs
		LEFT JOIN sensor_readings sr ON cs.sensor_reading_id = sr.id
		LEFT JOIN risk_assessments ra ON ra.check_session_id = cs.id
		WHERE cs.pond_id = ?
		ORDER BY cs.started_at DESC
		LIMIT ?
	`
	rows, err := r.DB.QueryContext(ctx, query, pondID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.HistoryItem
	for rows.Next() {
		var h models.HistoryItem
		if err := rows.Scan(
			&h.SessionID, &h.RiskLevel, &h.StartedAt,
			&h.Temperature, &h.PH, &h.Turbidity, &h.EstimatedDO,
		); err != nil {
			return nil, err
		}
		items = append(items, h)
	}

	// PENTING: cek error setelah loop selesai
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

// GetPondName mengambil nama kolam.
func (r *CheckSessionRepository) GetPondName(ctx context.Context, pondID int64) (string, error) {
	var name string
	err := r.DB.QueryRowContext(ctx,
		`SELECT name FROM ponds WHERE id = ?`, pondID,
	).Scan(&name)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return name, err
}
