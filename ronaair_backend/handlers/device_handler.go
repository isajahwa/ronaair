package handlers

import (
	"database/sql"
	"net/http"

	"github.com/ronaair/backend/models"
)

// DeviceHandler menangani endpoint device.
type DeviceHandler struct {
	DB *sql.DB
}

// GetDevices menangani GET /api/v1/device?pond_id=1.
func (h *DeviceHandler) GetDevices(w http.ResponseWriter, r *http.Request) {
	pondID := parsePondID(r)
	if pondID == 0 {
		writeError(w, http.StatusBadRequest, "pond_id wajib diisi")
		return
	}

	rows, err := h.DB.QueryContext(r.Context(),
		`SELECT id, device_code, device_type, status, last_seen
		 FROM devices WHERE pond_id = ?`, pondID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal mengambil data device")
		return
	}
	defer rows.Close()

	var devices []models.DeviceStatus
	for rows.Next() {
		var d models.DeviceStatus
		if err := rows.Scan(
			&d.ID, &d.DeviceCode, &d.DeviceType, &d.Status, &d.LastSeen,
		); err != nil {
			writeError(w, http.StatusInternalServerError, "Gagal membaca data device")
			return
		}
		devices = append(devices, d)
	}

	// PENTING: cek error setelah loop selesai
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal membaca data device")
		return
	}

	writeSuccess(w, "OK", devices)
}
