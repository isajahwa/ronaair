package services

import (
	"github.com/ronaair/backend/models"
)

// RiskEngine menilai risiko berdasarkan evidence yang tersedia.
//
// ⚠️ PENTING:
// Aturan dan threshold di bawah ini adalah PLACEHOLDER untuk prototype.
// Threshold final harus ditentukan berdasarkan literatur, data lokal,
// dan validasi ahli. Jangan klaim sebagai angka ilmiah final.
type RiskEngine struct{}

func NewRiskEngine() *RiskEngine {
	return &RiskEngine{}
}

// Assess menilai risiko dari data sensor terakhir.
// Return: risk_level, factors, explanation, recommendation.
func (e *RiskEngine) Assess(sensor *models.SensorReading) (
	string, []string, string, string,
) {
	if sensor == nil {
		return "NORMAL",
			[]string{"Belum ada data sensor"},
			"Belum ada data sensor yang tersedia.",
			"Pastikan perangkat sensor terhubung."
	}

	var factors []string
	score := 0

	// TODO: threshold placeholder. Ganti setelah validasi.
	if sensor.PH != nil {
		if *sensor.PH < 6.5 || *sensor.PH > 8.5 {
			factors = append(factors, "pH di luar rentang normal")
			score += 2
		} else if *sensor.PH < 6.8 || *sensor.PH > 8.0 {
			factors = append(factors, "pH sedikit di luar rentang ideal")
			score++
		}
	}

	if sensor.Turbidity != nil {
		if *sensor.Turbidity > 50 {
			factors = append(factors, "Turbidity tinggi")
			score += 2
		} else if *sensor.Turbidity > 25 {
			factors = append(factors, "Turbidity meningkat")
			score++
		}
	}

	if sensor.EstimatedDO != nil {
		if *sensor.EstimatedDO < 3 {
			factors = append(factors, "Estimasi DO rendah")
			score += 2
		} else if *sensor.EstimatedDO < 5 {
			factors = append(factors, "Estimasi DO perlu perhatian")
			score++
		}
	}

	if sensor.Temperature != nil {
		if *sensor.Temperature > 32 || *sensor.Temperature < 22 {
			factors = append(factors, "Suhu di luar rentang ideal")
			score++
		}
	}

	if len(factors) == 0 {
		factors = []string{"Semua parameter dalam rentang normal"}
	}

	var level, explanation, recommendation string
	switch {
	case score >= 5:
		level = "DARURAT"
		explanation = "Kombinasi evidence menunjukkan kondisi berisiko tinggi."
		recommendation = "Lakukan verifikasi kualitas air dan hubungi penyuluh."
	case score >= 3:
		level = "SIAGA"
		explanation = "Kombinasi evidence menunjukkan peningkatan risiko."
		recommendation = "Lakukan pemeriksaan lanjutan dan kurangi faktor risiko."
	case score >= 1:
		level = "WASPADA"
		explanation = "Ada perubahan yang perlu dipantau."
		recommendation = "Periksa kembali kondisi air dan pantau perubahan."
	default:
		level = "NORMAL"
		explanation = "Kondisi air relatif stabil."
		recommendation = "Lanjutkan pemantauan rutin."
	}

	return level, factors, explanation, recommendation
}
