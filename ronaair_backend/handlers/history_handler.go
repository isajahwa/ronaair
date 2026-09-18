package handlers

import (
	"net/http"

	"github.com/ronaair/backend/repositories"
)

type HistoryHandler struct {
	Repo *repositories.CheckSessionRepository
}

// GetHistory menangani GET /api/v1/history?pond_id=1&limit=20.
func (h *HistoryHandler) GetHistory(w http.ResponseWriter, r *http.Request) {
	pondID := parsePondID(r)
	if pondID == 0 {
		writeError(w, http.StatusBadRequest, "pond_id wajib diisi")
		return
	}

	limit := 20
	items, err := h.Repo.GetHistoryByPond(r.Context(), pondID, limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal mengambil riwayat")
		return
	}

	writeSuccess(w, "OK", items)
}
