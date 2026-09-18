package main

import (
	"log"
	"net/http"

	"github.com/ronaair/backend/config"
	"github.com/ronaair/backend/database"
	"github.com/ronaair/backend/routes"
)

func main() {
	// 1. Load konfigurasi
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("gagal load config: %v", err)
	}

	// 2. Koneksi ke MySQL
	db, err := database.Connect(cfg.DSN())
	if err != nil {
		log.Fatalf("gagal koneksi ke database: %v", err)
	}
	defer db.Close()
	log.Println("✅ Terhubung ke MySQL")

	// 3. Siapkan router
	mux := http.NewServeMux()
	handler := routes.RegisterRoutes(mux, cfg.APIVersion, db)

	// 4. Jalankan server
	addr := ":" + cfg.AppPort
	log.Printf("🚀 RonaAir backend berjalan di http://localhost%s", addr)
	log.Printf("   Health check: http://localhost%s/api/%s/health", addr, cfg.APIVersion)

	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("server gagal: %v", err)
	}
}
