package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Config menyimpan semua konfigurasi aplikasi.
type Config struct {
	AppPort    string
	AppEnv     string
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	APIVersion string
}

// Load membaca file .env dan mengembalikan Config.
func Load() (*Config, error) {
	// Coba baca .env. Kalau tidak ada, lanjut dengan environment variable sistem.
	_ = godotenv.Load()

	cfg := &Config{
		AppPort:    getEnv("APP_PORT", "8080"),
		AppEnv:     getEnv("APP_ENV", "development"),
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "3306"),
		DBUser:     getEnv("DB_USER", "root"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "ronaair"),
		APIVersion: getEnv("API_VERSION", "v1"),
	}

	return cfg, nil
}

// DSN mengembalikan string koneksi MySQL.
func (c *Config) DSN() string {
	return fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4&loc=Local",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName,
	)
}

// getEnv mengambil nilai env, atau default jika tidak ada.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}