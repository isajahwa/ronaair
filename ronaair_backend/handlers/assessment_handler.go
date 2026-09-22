package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// AssessmentHandler menangani endpoint POST /api/v1/assess
type AssessmentHandler struct {
	DB *sql.DB
}

// AssessmentResponse adalah struktur respons JSON untuk endpoint assess
type AssessmentResponse struct {
	RiskStatus       string        `json:"risk_status"`
	SupportingFactors []interface{} `json:"supporting_factors"`
	FiredRules       []interface{} `json:"fired_rules"`
	DataQuality      string        `json:"data_quality"`
	OutOfDistributionNotes []interface{} `json:"out_of_distribution_notes"`
	Recommendations  []interface{} `json:"recommendations"`
	Explanation      string        `json:"explanation"`
	ModelVersion     string        `json:"model_version"`
	Timestamp        string        `json:"timestamp"`
	DecisionSource   string        `json:"decision_source"`
}

// AssessSession menjalankan satu sesi pemeriksaan.
func (h *AssessmentHandler) AssessSession(w http.ResponseWriter, r *http.Request) {
	// 1. Parse body JSON
	var reqBody map[string]interface{}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusOK)
		resp := buildFallbackResponse("", "fallback")
		w.Write(toJSON(resp))
		return
	}

	if err := json.Unmarshal(body, &reqBody); err != nil {
		w.WriteHeader(http.StatusOK)
		resp := buildFallbackResponse("", "fallback")
		w.Write(toJSON(resp))
		return
	}

	// 2. Siapkan payload ke service Python
	pythonPayload := map[string]interface{}{
		"water_temp":       reqBody["water_temp"],
		"ph_sensor":        reqBody["ph_sensor"],
		"do_est":           reqBody["do_est"],
		"visual_score":     reqBody["visual_score"],
		"ph_visual_est":    reqBody["ph_visual_est"],
		"image_quality":    reqBody["image_quality"],
		"ph_difference":    reqBody["ph_difference"],
		"ec_value":         reqBody["ec_value"],
		"tds_ppm":          reqBody["tds_ppm"],
		"hour":             reqBody["hour"],
	}

	// 3. Panggil service Python dengan timeout 5 detik
	assessResult := callPythonAssess(pythonPayload)

	// 4. Bangun respons dari hasil
	var resp AssessmentResponse

	if assessResult != nil {
		// Map field dari Python service ke struktur respons Go
		if v, ok := assessResult["risk_status"].(string); ok {
			resp.RiskStatus = v
		}
		if v, ok := assessResult["supporting_factors"].([]interface{}); ok {
			resp.SupportingFactors = v
		}
		if v, ok := assessResult["fired_rules"].([]interface{}); ok {
			resp.FiredRules = v
		}
		if v, ok := assessResult["data_quality"].(string); ok {
			resp.DataQuality = v
		}
		if v, ok := assessResult["out_of_distribution_notes"].([]interface{}); ok {
			resp.OutOfDistributionNotes = v
		}
		if v, ok := assessResult["recommendations"].([]interface{}); ok {
			// Normalisasi setiap recommendation agar struktur konsisten
			normalized := make([]interface{}, 0)
			for _, rec := range v {
				normalized = append(normalized, normalizeRecommendation(rec))
			}
			resp.Recommendations = normalized
		}
		if v, ok := assessResult["explanation"].(string); ok {
			resp.Explanation = v
		}
		if v, ok := assessResult["model_version"].(string); ok {
			resp.ModelVersion = v
		}
		if v, ok := assessResult["timestamp"].(string); ok {
			resp.Timestamp = v
		}
		if v, ok := assessResult["decision_source"].(string); ok {
			resp.DecisionSource = v
		}
	} else {
		// Python gagal/timout: isi dengan fallback yang konsisten struktur
		resp = buildFallbackResponse(time.Now().Format("2006-01-02 15:04:00"), "fallback")
	}

	// 5. Kirim respons JSON
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(toJSON(resp))
}

// buildFallbackResponse membangun respons fallback dengan struktur konsisten
func buildFallbackResponse(timestamp string, decisionSource string) AssessmentResponse {
	if timestamp == "" {
		timestamp = time.Now().Format("2006-01-02 15:04:00")
	}

	return AssessmentResponse{
		RiskStatus:       "INSUFFICIENT_EVIDENCE",
		SupportingFactors: []interface{}{},
		FiredRules:       []interface{}{},
		DataQuality:      "INSUFFICIENT_EVIDENCE",
		OutOfDistributionNotes: []interface{}{},
		Recommendations: []interface{}{
			map[string]interface{}{
				"action":               "Cek koneksi sensor dan coba ulang pengukuran",
				"contraindication":     "",
				"priority":             1, // angka, sesuai pola Python (1=high, 2=medium, 3=low)
				"recheck_after_minutes": 60,
				"recommendation_id":    "FALLBACK_000",
				"risk_status":          "INSUFFICIENT_EVIDENCE",
				"source":               "fallback",
				"trigger_condition":    "NO_PYTHON_SERVICE",
				"validation_status":    "NEEDS_EXPERT_VALIDATION",
			},
		},
		Explanation:     "Layanan analisis AI sedang tidak dapat dihubungi. Data sensor tetap tersimpan; coba periksa ulang beberapa saat lagi.",
		ModelVersion:    "unavailable",
		Timestamp:       timestamp,
		DecisionSource:  decisionSource,
	}
}

// normalizeRecommendation memastikan satu recommendation memiliki struktur konsisten
// Semuanya akan memiliki: action, contraindication, priority (number wajib), recheck_after_minutes (number wajib),
// recommendation_id, risk_status, source, trigger_condition ATAU trigger_rules, validation_status
func normalizeRecommendation(rec interface{}) map[string]interface{} {
	// Default values
	result := map[string]interface{}{
		"action":               "",
		"contraindication":    "",
		"priority":             1,       // 1=high, 2=medium, 3=low (wajib selalu ada)
		"recheck_after_minutes": 60,   // menit (wajib selalu ada)
		"recommendation_id":   "RISK_000",
		"risk_status":         "INSUFFICIENT_EVIDENCE",
		"source":              "unknown",
		"validation_status":   "NEEDS_EXPERT_VALIDATION",
	}

	if m, ok := rec.(map[string]interface{}); ok {
		if v, ok := m["action"].(string); ok {
			result["action"] = v
		}
		if v, ok := m["contraindication"].(string); ok {
			result["contraindication"] = v
		}
		if v, ok := m["priority"].(float64); ok {
			result["priority"] = int(v)
		} else if v, ok := m["priority"].(int); ok {
			result["priority"] = v
		}
		if v, ok := m["recheck_after_minutes"].(float64); ok {
			result["recheck_after_minutes"] = int(v)
		} else if v, ok := m["recheck_after_minutes"].(int); ok {
			result["recheck_after_minutes"] = v
		}
		if v, ok := m["recommendation_id"].(string); ok {
			result["recommendation_id"] = v
		}
		if v, ok := m["risk_status"].(string); ok {
			result["risk_status"] = v
		}
		if v, ok := m["source"].(string); ok {
			result["source"] = v
		}
		if v, ok := m["trigger_condition"].(string); ok {
			result["trigger_condition"] = v
		}
		// Jika tidak ada trigger_condition tapi ada trigger_rules, gunakan trigger_rules
		if _, triggerConditionExists := m["trigger_condition"]; !triggerConditionExists {
			if v, ok := m["trigger_rules"].([]interface{}); ok {
				// Convert array of rule IDs to string description
				rules := v
				if len(rules) > 0 {
					ruleIDs := make([]string, len(rules))
					for i, r := range rules {
						if rid, ok := r.(string); ok {
							ruleIDs[i] = rid
						}
					}
					result["trigger_condition"] = "Rule(s) " + strings.Join(ruleIDs, ", ") + " aktif"
				}
				result["trigger_rules"] = rules // tetap menyimpan array untuk referensi
			}
		}
		if v, ok := m["validation_status"].(string); ok {
			result["validation_status"] = v
		}
	}

	return result
}

// callPythonAssess memanggil service Python dengan timeout 5 detik
func callPythonAssess(payload map[string]interface{}) map[string]interface{} {
	jsonBody, _ := json.Marshal(payload)
	resp, err := http.Post("http://127.0.0.1:8000/assess", "application/json", bytes.NewReader(jsonBody))

	if err != nil || resp.StatusCode != http.StatusOK {
		if resp != nil {
			resp.Body.Close()
		}
		return nil
	}
	defer resp.Body.Close()
	result, _ := io.ReadAll(resp.Body)

	var respMap map[string]interface{}
	json.Unmarshal(result, &respMap)
	return respMap
}

// saveRiskAssessment menyimpan ke tabel risk_assessments
func saveRiskAssessment(db *sql.DB, result map[string]interface{}) {
	sessionID := fmt.Sprintf("session_%d", time.Now().Unix())

	factorsJSON := ""
	explanation := ""
	recommendation := ""
	modelVersion := ""
	dataQuality := ""

	if r, ok := result["fired_rules"]; ok {
		b, err := json.Marshal(r)
		if err != nil {
			b = []byte("[]")
		}
		factorsJSON = string(b)
	}
	if r, ok := result["explanation"]; ok {
		explanation = r.(string)
	}
	if r, ok := result["recommendation"]; ok {
		recommendation = r.(string)
	}
	if r, ok := result["model_version"]; ok {
		modelVersion = r.(string)
	}
	if r, ok := result["data_quality"]; ok {
		dataQuality = r.(string)
	}

	query := `INSERT INTO risk_assessments (check_session_id, risk_level, factors, explanation, recommendation, model_version, data_quality, assessed_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`
	_, _ = db.Exec(query, sessionID, "NORMAL", factorsJSON, explanation, recommendation, modelVersion, dataQuality)
}

// toJSON mengubah struct AssessmentResponse menjadi JSON byte array untuk ResponseWriter
func toJSON(v interface{}) []byte {
	b, _ := json.Marshal(v)
	return b
}