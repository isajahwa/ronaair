package handlers

import (
	"net/http"
	"time"

	"github.com/ronaair/backend/models"
	"github.com/ronaair/backend/repositories"
	"github.com/ronaair/backend/services"
)

type DashboardHandler struct {
	SensorRepo  *repositories.SensorRepository
	SessionRepo *repositories.CheckSessionRepository
	RiskEngine  *services.RiskEngine
}

// GetDashboard menangani GET /api/v1/dashboard?pond_id=1.
func (h *DashboardHandler) GetDashboard(w http.ResponseWriter, r *http.Request) {
	pondID := parsePondID(r)
	if pondID == 0 {
		writeError(w, http.StatusBadRequest, "pond_id wajib diisi")
		return
	}

	// Nama kolam
	pondName, err := h.SessionRepo.GetPondName(r.Context(), pondID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal mengambil data kolam")
		return
	}

	// Sensor terbaru
	sensor, err := h.SensorRepo.GetLatestByPond(r.Context(), pondID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal mengambil data sensor")
		return
	}

	// Risk assessment
	level, factors, explanation, recommendation := h.RiskEngine.Assess(sensor)

	var lastUpdated *time.Time
	if sensor != nil {
		lastUpdated = &sensor.RecordedAt
	}

	resp := models.DashboardResponse{
		PondID:            pondID,
		PondName:          pondName,
		RiskLevel:         level,
		Factors:           factors,
		Explanation:       explanation,
		Recommendation:    recommendation,
		Sensor:            sensor,
		LastUpdated:       lastUpdated,
		IsOnline:          true,
		IsSensorConnected: sensor != nil,
	}

	writeSuccess(w, "OK", resp)
}
