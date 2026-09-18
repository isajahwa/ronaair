package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/ronaair/backend/models"
)

// HealthHandler menangani GET /api/v1/health.
// Sekarang juga mengecek koneksi database.
type HealthHandler struct {
	DB *sql.DB
}

func (h *HealthHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	dbStatus := "ok"
	if err := h.DB.Ping(); err != nil {
		dbStatus = "error"
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	resp := models.APIResponse{
		Status:  "success",
		Message: "RonaAir backend is running",
		Data: map[string]interface{}{
			"service":   "ronaair-backend",
			"version":   "0.2.0",
			"timestamp": time.Now().Format(time.RFC3339),
			"database":  dbStatus,
		},
	}

	json.NewEncoder(w).Encode(resp)
}
