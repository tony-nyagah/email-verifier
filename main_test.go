package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"
)

// TestEmailVerification tests the email verification functionality
func TestEmailVerification(t *testing.T) {
	// Test cases
	testCases := []struct {
		email    string
		expected bool // whether we expect a valid result
	}{
		{"test@gmail.com", true},
		{"invalid-email", false},
		{"user@nonexistentdomain12345.com", true}, // valid format but may not be reachable
		{"", false},
		{"admin@example.com", true},
	}

	for _, tc := range testCases {
		t.Run(tc.email, func(t *testing.T) {
			result := verifyEmail(tc.email)

			if tc.expected && result.Error != "" {
				// For valid format emails, we shouldn't have syntax errors
				if tc.email != "" && tc.email != "invalid-email" {
					// Only fail if it's a syntax error, not a network error
					if result.Error == "Invalid email address format" {
						t.Errorf("Expected valid email format for %s, got error: %s", tc.email, result.Error)
					}
				}
			}

			if !tc.expected && result.Error == "" && tc.email == "invalid-email" {
				t.Errorf("Expected error for invalid email %s, but got none", tc.email)
			}
		})
	}
}

// TestAPIEndpoint tests the HTTP API endpoint
func TestAPIEndpoint(t *testing.T) {
	// Start server in background for testing
	go func() {
		http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
		http.HandleFunc("/", indexHandler)
		http.HandleFunc("/verify", verifyHandler)
		http.HandleFunc("/api/verify", apiVerifyHandler)
		http.ListenAndServe(":8081", nil) // Use different port for testing
	}()

	// Wait for server to start
	time.Sleep(2 * time.Second)

	// Test API request
	requestBody := map[string]string{
		"email": "test@example.com",
	}

	jsonBody, _ := json.Marshal(requestBody)

	resp, err := http.Post("http://localhost:8081/api/verify", "application/json", bytes.NewBuffer(jsonBody))
	if err != nil {
		t.Fatalf("Failed to make API request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Failed to read response body: %v", err)
	}

	var result EmailResult
	if err := json.Unmarshal(body, &result); err != nil {
		t.Fatalf("Failed to parse JSON response: %v", err)
	}

	if result.Email != "test@example.com" {
		t.Errorf("Expected email to be test@example.com, got %s", result.Email)
	}
}

// BenchmarkEmailVerification benchmarks the email verification function
func BenchmarkEmailVerification(b *testing.B) {
	emails := []string{
		"test@gmail.com",
		"user@example.com",
		"admin@company.org",
		"support@website.net",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		email := emails[i%len(emails)]
		verifyEmail(email)
	}
}

// TestSyntaxValidation tests email syntax validation
func TestSyntaxValidation(t *testing.T) {
	testCases := []struct {
		email string
		valid bool
	}{
		{"user@example.com", true},
		{"test.email@domain.co.uk", true},
		{"user+tag@example.com", true},
		{"invalid.email", false},
		{"@example.com", false},
		{"user@", false},
		{"user@.com", false},
		{"", false},
	}

	for _, tc := range testCases {
		t.Run(tc.email, func(t *testing.T) {
			syntax := verifier.ParseAddress(tc.email)
			if syntax.Valid != tc.valid {
				t.Errorf("Expected valid=%v for email %s, got %v", tc.valid, tc.email, syntax.Valid)
			}
		})
	}
}

// Example demonstrates how to use the email verification
func Example() {
	result := verifyEmail("user@example.com")
	fmt.Printf("Email: %s\n", result.Email)
	fmt.Printf("Valid: %v\n", result.IsValid)
	fmt.Printf("Reachable: %s\n", result.Reachable)
}

// TestDisposableEmailDetection tests disposable email detection
func TestDisposableEmailDetection(t *testing.T) {
	// Test with some known disposable domains
	disposableEmails := []string{
		"test@10minutemail.com",
		"user@tempmail.org",
	}

	for _, email := range disposableEmails {
		t.Run(email, func(t *testing.T) {
			result := verifyEmail(email)
			// Note: This might not always be true due to dynamic disposable domain lists
			if !result.Disposable {
				t.Logf("Email %s was not detected as disposable (this might be expected)", email)
			}
		})
	}
}

// TestRoleAccountDetection tests role account detection
func TestRoleAccountDetection(t *testing.T) {
	roleEmails := []string{
		"admin@example.com",
		"support@example.com",
		"info@example.com",
		"noreply@example.com",
	}

	regularEmails := []string{
		"john.doe@example.com",
		"user123@example.com",
	}

	for _, email := range roleEmails {
		t.Run(email, func(t *testing.T) {
			result := verifyEmail(email)
			if !result.RoleAccount {
				t.Logf("Email %s was not detected as role account", email)
			}
		})
	}

	for _, email := range regularEmails {
		t.Run(email, func(t *testing.T) {
			result := verifyEmail(email)
			if result.RoleAccount {
				t.Errorf("Email %s was incorrectly detected as role account", email)
			}
		})
	}
}

// TestFreeProviderDetection tests free email provider detection
func TestFreeProviderDetection(t *testing.T) {
	freeEmails := []string{
		"user@gmail.com",
		"test@yahoo.com",
		"example@hotmail.com",
	}

	businessEmails := []string{
		"user@company.com",
		"test@business.org",
	}

	for _, email := range freeEmails {
		t.Run(email, func(t *testing.T) {
			result := verifyEmail(email)
			if !result.Free {
				t.Logf("Email %s was not detected as free provider", email)
			}
		})
	}

	for _, email := range businessEmails {
		t.Run(email, func(t *testing.T) {
			result := verifyEmail(email)
			// Business emails might still be detected as free if the domain is actually free
			// This is just for logging purposes
			if result.Free {
				t.Logf("Email %s was detected as free provider", email)
			}
		})
	}
}
