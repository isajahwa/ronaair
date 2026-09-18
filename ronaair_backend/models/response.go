package models

// APIResponse adalah bentuk standar semua response dari backend.
type APIResponse struct {
	Status  string      `json:"status"`            // "success" atau "error"
	Message string      `json:"message,omitempty"` // pesan singkat
	Data    interface{} `json:"data,omitempty"`    // data utama
	Error   string      `json:"error,omitempty"`   // detail error
}
