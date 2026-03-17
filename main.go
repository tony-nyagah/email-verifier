package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"strings"

	emailverifier "github.com/AfterShip/email-verifier"
)

type EmailResult struct {
	Email   string `json:"email"`
	IsValid bool   `json:"is_valid"`

	Disposable   bool   `json:"disposable"`
	RoleAccount  bool   `json:"role_account"`
	Free         bool   `json:"free"`
	HasMxRecords bool   `json:"has_mx_records"`
	Suggestion   string `json:"suggestion,omitempty"`
	Error        string `json:"error,omitempty"`
	Username     string `json:"username,omitempty"`
	Domain       string `json:"domain,omitempty"`
}

var verifier *emailverifier.Verifier

func init() {
	verifier = emailverifier.NewVerifier().
		EnableDomainSuggest().
		EnableAutoUpdateDisposable()
}

func main() {
	// Parse command line flags
	healthCheck := flag.Bool("health-check", false, "Run health check and exit")
	port := flag.String("port", "8081", "Port to run the server on")
	flag.Parse()

	// Handle health check
	if *healthCheck {
		if err := performHealthCheck(*port); err != nil {
			fmt.Printf("Health check failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Health check passed")
		os.Exit(0)
	}

	// Get port from environment variable if set
	if envPort := os.Getenv("PORT"); envPort != "" {
		*port = envPort
	}

	// Serve static files
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))

	// Routes
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/verify", verifyHandler)
	http.HandleFunc("/api/verify", apiVerifyHandler)
	http.HandleFunc("/health", healthHandler)

	fmt.Printf("🚀 Email Verifier Server starting on http://localhost:%s\n", *port)
	log.Fatal(http.ListenAndServe(":"+*port, nil))
}

func performHealthCheck(port string) error {
	resp, err := http.Get("http://localhost:" + port + "/health")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check returned status %d", resp.StatusCode)
	}
	return nil
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "healthy",
		"service": "email-verifier",
	})
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	tmpl := template.Must(template.ParseFiles("templates/index.html"))
	data := struct {
		Title string
	}{
		Title: "Email Verifier",
	}
	tmpl.Execute(w, data)
}

func verifyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	email := strings.TrimSpace(r.FormValue("email"))
	if email == "" {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	result := verifyEmail(email)

	tmpl := template.Must(template.ParseFiles("templates/result.html"))
	tmpl.Execute(w, result)
}

func apiVerifyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var request struct {
		Email string `json:"email"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	result := verifyEmail(request.Email)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func verifyEmail(email string) *EmailResult {
	result := &EmailResult{
		Email: email,
	}

	// Basic validation first
	if email == "" {
		result.Error = "Email address is required"
		return result
	}

	// Parse and validate syntax
	syntax := verifier.ParseAddress(email)
	result.Username = syntax.Username
	result.Domain = syntax.Domain
	result.IsValid = syntax.Valid

	if !syntax.Valid {
		result.Error = "Invalid email address format"
		return result
	}

	// Perform full verification
	verifyResult, err := verifier.Verify(email)
	if err != nil {
		result.Error = fmt.Sprintf("Verification failed: %v", err)
		return result
	}

	// Map results
	result.Disposable = verifyResult.Disposable
	result.RoleAccount = verifyResult.RoleAccount
	result.Free = verifyResult.Free
	result.HasMxRecords = verifyResult.HasMxRecords
	result.Suggestion = verifyResult.Suggestion

	return result
}
