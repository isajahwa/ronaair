package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/ronaair/backend/models"
)

// writeSuccess mengirim response sukses.
func writeSuccess(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(models.APIResponse{
		Status:  "success",
		Message: message,
		Data:    data,
	})
}

// writeError mengirim response error.
func writeError(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(models.APIResponse{
		Status: "error",
		Error:  message,
	})
}

// parsePondID membaca query ?pond_id=1.
func parsePondID(r *http.Request) int64 {
	v := r.URL.Query().Get("pond_id")
	if v == "" {
		return 0
	}
	id, err := strconv.ParseInt(v, 10, 64)
	if err != nil {
		return 0
	}
	return id
}
