package models

import "time"

// DashboardResponse adalah response untuk GET /dashboard.
type DashboardResponse struct {
	PondID            int64          `json:"pond_id"`
	PondName          string         `json:"pond_name"`
	RiskLevel         string         `json:"risk_level"`
	Factors           []string       `json:"factors"`
	Explanation       string         `json:"explanation"`
	Recommendation    string         `json:"recommendation"`
	Sensor            *SensorReading `json:"sensor,omitempty"`
	Visual            *VisualSummary `json:"visual,omitempty"`
	LastUpdated       *time.Time     `json:"last_updated,omitempty"`
	IsOnline          bool           `json:"is_online"`
	IsSensorConnected bool           `json:"is_sensor_connected"`
}

// VisualSummary adalah ringkasan analisis visual terakhir.
type VisualSummary struct {
	Indicator  string  `json:"indicator"`
	Confidence float64 `json:"confidence"`
}

// HistoryItem adalah satu baris riwayat.
type HistoryItem struct {
	SessionID   int64     `json:"session_id"`
	RiskLevel   string    `json:"risk_level"`
	StartedAt   time.Time `json:"started_at"`
	Temperature *float64  `json:"temperature,omitempty"`
	PH          *float64  `json:"ph,omitempty"`
	Turbidity   *float64  `json:"turbidity,omitempty"`
	EstimatedDO *float64  `json:"estimated_do,omitempty"`
}

// DeviceStatus adalah status satu device.
type DeviceStatus struct {
	ID         int64      `json:"id"`
	DeviceCode string     `json:"device_code"`
	DeviceType string     `json:"device_type"`
	Status     string     `json:"status"`
	LastSeen   *time.Time `json:"last_seen,omitempty"`
}
