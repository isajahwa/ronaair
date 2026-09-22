package routes

import (
	"database/sql"
	"net/http"

	"github.com/ronaair/backend/handlers"
	"github.com/ronaair/backend/middleware"
	"github.com/ronaair/backend/repositories"
	"github.com/ronaair/backend/services"
)

// RegisterRoutes mendaftarkan semua endpoint API.
func RegisterRoutes(mux *http.ServeMux, apiVersion string, db *sql.DB) http.Handler {
	// === Inisialisasi repository ===
	sensorRepo := repositories.NewSensorRepository(db)
	sessionRepo := repositories.NewCheckSessionRepository(db)

	// === Inisialisasi service ===
	riskEngine := services.NewRiskEngine()

	// === Inisialisasi handler ===
	healthHandler := &handlers.HealthHandler{DB: db}
	sensorHandler := &handlers.SensorHandler{Repo: sensorRepo}
	dashboardHandler := &handlers.DashboardHandler{
		SensorRepo:  sensorRepo,
		SessionRepo: sessionRepo,
		RiskEngine:  riskEngine,
	}
	historyHandler := &handlers.HistoryHandler{Repo: sessionRepo}
	deviceHandler := &handlers.DeviceHandler{DB: db}

	// === Daftar endpoint ===
	prefix := "/api/" + apiVersion

	mux.Handle("GET "+prefix+"/health", healthHandler)

	mux.HandleFunc("POST "+prefix+"/sensor", sensorHandler.CreateSensorReading)
	mux.HandleFunc("GET "+prefix+"/sensor/latest", sensorHandler.GetLatestSensor)

	mux.HandleFunc("GET "+prefix+"/dashboard", dashboardHandler.GetDashboard)
	mux.HandleFunc("GET "+prefix+"/history", historyHandler.GetHistory)
	mux.HandleFunc("GET "+prefix+"/device", deviceHandler.GetDevices)

	assessmentHandler := &handlers.AssessmentHandler{}
	mux.HandleFunc("POST "+prefix+"/assess", assessmentHandler.AssessSession)

// Bungkus dengan middleware
	return middleware.Logger(mux)
}