package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"math/rand"
	"net/http"
	"os"
	"time"
)

// Konfigurasi simulator.
const (
	defaultBackendURL = "http://localhost:8080/api/v1/sensor"
	pondID            = 1
	deviceID          = 1
	intervalSeconds   = 5
)

// SensorPayload adalah bentuk data yang dikirim ke backend.
type SensorPayload struct {
	PondID      int64   `json:"pond_id"`
	DeviceID    int64   `json:"device_id"`
	Temperature float64 `json:"temperature"`
	PH          float64 `json:"ph"`
	Turbidity   float64 `json:"turbidity"`
	EstimatedDO float64 `json:"estimated_do"`
}

// Mode simulasi.
type Mode string

const (
	ModeNormal  Mode = "normal"
	ModeWaspada Mode = "waspada"
	ModeKritis  Mode = "kritis"
)

func main() {
	// Baca argumen: go run cmd/simulator/main.go [mode]
	mode := ModeNormal
	if len(os.Args) > 1 {
		mode = Mode(os.Args[1])
	}

	backendURL := defaultBackendURL
	if v := os.Getenv("BACKEND_URL"); v != "" {
		backendURL = v
	}

	log.Printf("🤖 RonaAir Sensor Simulator")
	log.Printf("   Backend  : %s", backendURL)
	log.Printf("   Mode     : %s", mode)
	log.Printf("   Interval : %d detik", intervalSeconds)
	log.Printf("   Tekan Ctrl+C untuk berhenti.\n")

	// State awal
	baseTemp := 28.0
	basePH := 7.2
	baseTurb := 15.0
	baseDO := 6.2

	// Sesuaikan base berdasarkan mode
	switch mode {
	case ModeWaspada:
		baseTemp = 29.5
		basePH = 6.9
		baseTurb = 28.0
		baseDO = 5.0
	case ModeKritis:
		baseTemp = 32.0
		basePH = 6.3
		baseTurb = 55.0
		baseDO = 3.0
	}

	ticker := time.NewTicker(intervalSeconds * time.Second)
	defer ticker.Stop()

	tick := 0
	for range ticker.C {
		tick++

		// Fluktuasi halus pakai gelombang sinus + noise.
		wave := math.Sin(float64(tick)/3.0) * 0.3
		noise := (rand.Float64() - 0.5) * 0.4

		payload := SensorPayload{
			PondID:      pondID,
			DeviceID:    deviceID,
			Temperature: round1(baseTemp + wave + noise),
			PH:          round2(basePH + wave*0.1 + noise*0.05),
			Turbidity:   round1(baseTurb + wave*2 + noise*2),
			EstimatedDO: round2(baseDO - wave*0.2 + noise*0.1),
		}

		if err := postData(backendURL, payload); err != nil {
			log.Printf("❌ gagal kirim: %v", err)
		} else {
			log.Printf("✅ suhu=%.1f°C pH=%.2f turb=%.1fNTU DO=%.2f mg/L",
				payload.Temperature, payload.PH,
				payload.Turbidity, payload.EstimatedDO)
		}
	}
}

// postData mengirim payload ke backend.
func postData(url string, payload SensorPayload) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("backend menolak dengan status %d", resp.StatusCode)
	}
	return nil
}

// round1 membulatkan ke 1 angka desimal.
func round1(v float64) float64 {
	return math.Round(v*10) / 10
}

// round2 membulatkan ke 2 angka desimal.
func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
