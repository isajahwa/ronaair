package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ronaair/backend/models"
	"github.com/ronaair/backend/repositories"
)

type SensorHandler struct {
	Repo *repositories.SensorRepository
}

// CreateSensorReading menangani POST /api/v1/sensor.
func (h *SensorHandler) CreateSensorReading(w http.ResponseWriter, r *http.Request) {
	var req models.SensorReadingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Format JSON tidak valid")
		return
	}

	if req.PondID == 0 {
		writeError(w, http.StatusBadRequest, "pond_id wajib diisi")
		return
	}

	id, err := h.Repo.Insert(r.Context(), req)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal menyimpan data sensor")
		return
	}

	writeSuccess(w, "Data sensor tersimpan", map[string]interface{}{
		"id": id,
	})
}

// GetLatestSensor menangani GET /api/v1/sensor/latest?pond_id=1.
func (h *SensorHandler) GetLatestSensor(w http.ResponseWriter, r *http.Request) {
	pondID := parsePondID(r)
	if pondID == 0 {
		writeError(w, http.StatusBadRequest, "pond_id wajib diisi")
		return
	}

	sensor, err := h.Repo.GetLatestByPond(r.Context(), pondID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal mengambil data sensor")
		return
	}
	if sensor == nil {
		writeError(w, http.StatusNotFound, "Belum ada data sensor")
		return
	}

	writeSuccess(w, "OK", sensor)
}
