package models

import "time"

// SensorReading adalah satu baris data pembacaan sensor.
type SensorReading struct {
	ID          int64     `json:"id"`
	PondID      int64     `json:"pond_id"`
	DeviceID    *int64    `json:"device_id,omitempty"`
	Temperature *float64  `json:"temperature,omitempty"`
	PH          *float64  `json:"ph,omitempty"`
	Turbidity   *float64  `json:"turbidity,omitempty"`
	EstimatedDO *float64  `json:"estimated_do,omitempty"`
	MeasuredDO  *float64  `json:"measured_do,omitempty"`
	ECTDS       *float64  `json:"ec_tds,omitempty"`
	RecordedAt  time.Time `json:"recorded_at"`
	CreatedAt   time.Time `json:"created_at"`
}

// SensorReadingRequest adalah payload dari ESP32 / mock.
type SensorReadingRequest struct {
	PondID      int64    `json:"pond_id"`
	DeviceID    *int64   `json:"device_id,omitempty"`
	Temperature *float64 `json:"temperature,omitempty"`
	PH          *float64 `json:"ph,omitempty"`
	Turbidity   *float64 `json:"turbidity,omitempty"`
	EstimatedDO *float64 `json:"estimated_do,omitempty"`
	MeasuredDO  *float64 `json:"measured_do,omitempty"`
	ECTDS       *float64 `json:"ec_tds,omitempty"`
}
