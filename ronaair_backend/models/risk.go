package models

import "time"

// RiskAssessment adalah hasil penilaian risiko satu sesi.
type RiskAssessment struct {
	ID             int64     `json:"id"`
	CheckSessionID int64     `json:"check_session_id"`
	RiskLevel      string    `json:"risk_level"`
	Factors        []string  `json:"factors"`
	Explanation    string    `json:"explanation"`
	Recommendation string    `json:"recommendation"`
	AssessedAt     time.Time `json:"assessed_at"`
}
