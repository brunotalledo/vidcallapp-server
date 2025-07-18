import Foundation
import BraintreeDropIn

struct BraintreeConfig {
    // MARK: - Environment Configuration
    static let isProduction = false // Set to true for production
    
    // MARK: - Braintree Credentials
    // Client token generated from your server
    static let clientToken = isProduction ? 
        "YOUR_PRODUCTION_CLIENT_TOKEN" : 
        "eyJ2ZXJzaW9uIjoyLCJhdXRob3JpemF0aW9uRmluZ2VycHJpbnQiOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpGVXpJMU5pSXNJbXRwWkNJNklqSXdNVGd3TkRJMk1UWXRjMkZ1WkdKdmVDSXNJbWx6Y3lJNkltaDBkSEJ6T2k4dllYQnBMbk5oYm1SaWIzZ3VZbkpoYVc1MGNtVmxaMkYwWlhkaGVTNWpiMjBpZlEuZXlKbGVIQWlPakUzTlRFeU5UWXhPVE1zSW1wMGFTSTZJakZpTlRnMFlURmxMVFpoWXpVdE5EazRPUzA0Tm1RekxXUmhaR0l5T1dOaVptUTNaU0lzSW5OMVlpSTZJbXQyTjNKdU0zcG9lV2gzYTNseVluRWlMQ0pwYzNNaU9pSm9kSFJ3Y3pvdkwyRndhUzV6WVc1a1ltOTRMbUp5WVdsdWRISmxaV2RoZEdWM1lYa3VZMjl0SWl3aWJXVnlZMmhoYm5RaU9uc2ljSFZpYkdsalgybGtJam9pYTNZM2NtNHplbWg1YUhkcmVYSmljU0lzSW5abGNtbG1lVjlqWVhKa1gySjVYMlJsWm1GMWJIUWlPbVpoYkhObGZTd2ljbWxuYUhSeklqcGJJbTFoYm1GblpWOTJZWFZzZENKZExDSnpZMjl3WlNJNld5SkNjbUZwYm5SeVpXVTZWbUYxYkhRaVhTd2liM0IwYVc5dWN5STZlMzE5Lmg2TEZFcUhmRDI2MHhhclRPeUsxV1NrNC1HaVdHMVFQRDJfR2R2ZXpjTmgyRGlXNEFvdTk0UzBXOVRBU01aeG9helZMTndjYXFsSGFFUGl6anFtbW5nIiwiY29uZmlnVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5icmFpbnRyZWVnYXRld2F5LmNvbTo0NDMvbWVyY2hhbnRzL2t2N3JuM3poeWh3a3lyYnEvY2xpZW50X2FwaS92MS9jb25maWd1cmF0aW9uIiwiZ3JhcGhRTCI6eyJ1cmwiOiJodHRwczovL3BheW1lbnRzLnNhbmRib3guYnJhaW50cmVlLWFwaS5jb20vZ3JhcGhxbCIsImRhdGUiOiIyMDE4LTA1LTA4IiwiZmVhdHVyZXMiOlsidG9rZW5pemVfY3JlZGl0X2NhcmRzIl19LCJjbGllbnRBcGlVcmwiOiJodHRwczovL2FwaS5zYW5kYm94LmJyYWludHJlZWdhdGV3YXkuY29tOjQ0My9tZXJjaGFudHMva3Y3cm4zemh5aHdreXJicS9jbGllbnRfYXBpIiwiZW52aXJvbm1lbnQiOiJzYW5kYm94IiwibWVyY2hhbnRJZCI6Imt2N3JuM3poeWh3a3lyYnEiLCJhc3NldHNVcmwiOiJodHRwczovL2Fzc2V0cy5icmFpbnRyZWVnYXRld2F5LmNvbSIsImF1dGhVcmwiOiJodHRwczovL2F1dGgudmVubW8uc2FuZGJveC5icmFpbnRyZWVnYXRld2F5LmNvbSIsInZlbm1vIjoib2ZmIiwiY2hhbGxlbmdlcyI6W10sInRocmVlRFNlY3VyZUVuYWJsZWQiOnRydWUsImFuYWx5dGljcyI6eyJ1cmwiOiJodHRwczovL2FyaWdpbi1hbmFseXRpY3Mtc2FuZC5zYW5kYm94LmJyYWludHJlZS1hcGkuY29tL2t2N3JuM3poeWh3a3lyYnEifSwicGF5cGFsRW5hYmxlZCI6dHJ1ZSwicGF5cGFsIjp7ImJpbGxpbmdBZ3JlZW1lbnRzRW5hYmxlZCI6dHJ1ZSwiZW52aXJvbm1lbnROb05ldHdvcmsiOnRydWUsInVudmV0dGVkTWVyY2hhbnQiOmZhbHNlLCJhbGxvd0h0dHAiOnRydWUsImRpc3BsYXlOYW1lIjoiVmlkZHkiLCJjbGllbnRJZCI6bnVsbCwiYmFzZVVybCI6Imh0dHBzOi8vYXNzZXRzLmJyYWludHJlZWdhdGV3YXkuY29tIiwiYXNzZXRzVXJsIjoiaHR0cHM6Ly9jaGVja291dC5wYXlwYWwuY29tIiwiZGlyZWN0QmFzZVVybCI6bnVsbCwiZW52aXJvbm1lbnQiOiJvZmZsaW5lIiwiYnJhaW50cmVlQ2xpZW50SWQiOiJtYXN0ZXJjbGllbnQzIiwibWVyY2hhbnRBY2NvdW50SWQiOiJ2aWRkeSIsImN1cnJlbmN5SXNvQ29kZSI6IlVTRCJ9fQ=="
    
    // MARK: - Currency Configuration
    static let currencyCode = "USD"
    static let currencySymbol = "$"
    
    // MARK: - Minimum/Maximum Amounts
    static let minimumAmount: Double = 1.0
    static let maximumAmount: Double = 1000.0
    
    // MARK: - Server Endpoints (for production)
    static let serverBaseURL = isProduction ? 
        "https://your-production-server.com" : 
        "http://localhost:3001"
    
    static let createTransactionEndpoint = "/api/braintree/transactions"
    static let getClientTokenEndpoint = "/api/braintree/client-token"
    
    // MARK: - Error Messages
    static let errorMessages = [
        "invalid_amount": "Please enter a valid amount between $1.00 and $1,000.00",
        "network_error": "Network error. Please check your connection and try again.",
        "payment_failed": "Payment failed. Please try again or use a different payment method.",
        "invalid_card": "Invalid card information. Please check your details and try again."
    ]
    
    // MARK: - Validation
    static func isValidAmount(_ amount: Double) -> Bool {
        return amount >= minimumAmount && amount <= maximumAmount
    }
    
    static func formatAmount(_ amount: Double) -> String {
        return String(format: "%.2f", amount)
    }
} 