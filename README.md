# Email Verifier

A beautiful and powerful Go web application for email verification without sending any emails. Built with the [AfterShip Email Verifier](https://github.com/AfterShip/email-verifier) library.

## Features

- **Email Address Validation**: Validates if a string contains a valid email format
- **SMTP Verification**: Performs email verification lookup via SMTP to check if the mailbox exists
- **MX Record Validation**: Checks DNS MX records for the given domain
- **Disposable Email Detection**: Identifies temporary and disposable email addresses
- **Role Account Detection**: Detects role-based emails like admin@, support@, info@
- **Free Provider Detection**: Identifies emails from free providers (Gmail, Yahoo, etc.)
- **Domain Typo Suggestions**: Suggests corrections for misspelled domains
- **Beautiful Web Interface**: Modern, responsive UI with glassmorphism design
- **REST API**: Programmatic access via JSON API

## Screenshots

The application features a modern, gradient-based design with:
- Clean, intuitive form interface
- Detailed verification results with visual indicators
- Feature overview cards
- API usage documentation
- Responsive design for all devices

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd email-verifier
```

2. Ensure you have Go 1.22+ installed:
```bash
go version
```

3. Install dependencies:
```bash
go mod tidy
```

4. Run the application:
```bash
go run main.go
```

5. Open your browser and navigate to:
```
http://localhost:8080
```

## 🐳 Docker / GitHub Container Registry

The application is automatically built and published to GitHub Container Registry (GHCR) via GitHub Actions.

### Using Pre-built Docker Images

```bash
# Pull the latest image
docker pull ghcr.io/yourusername/email-verifier:latest

# Run the container
docker run -p 8080:8080 ghcr.io/yourusername/email-verifier:latest

# Run with custom port
docker run -p 3000:8080 -e PORT=8080 ghcr.io/yourusername/email-verifier:latest
```

### Available Tags

- `latest` - Latest build from main branch
- `main` - Same as latest
- `v1.0.0` - Specific version tags
- `sha-abc1234` - Specific commit builds

### Docker Compose

```yaml
version: '3.8'
services:
  email-verifier:
    image: ghcr.io/yourusername/email-verifier:latest
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
    restart: unless-stopped
```

## Usage

### Web Interface

1. Visit `http://localhost:8080` in your browser
2. Enter an email address in the input field
3. Click "Verify Email" to see detailed results
4. View comprehensive verification results including:
   - Email syntax validation
   - Domain and MX record checks
   - SMTP server verification
   - Disposable email detection
   - Role account identification
   - Free provider detection

### API Usage

Send a POST request to verify emails programmatically:

```bash
curl -X POST http://localhost:8080/api/verify \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

**Response Example:**
```json
{
  "email": "user@example.com",
  "is_valid": true,
  "reachable": "unknown",
  "disposable": false,
  "role_account": false,
  "free": false,
  "has_mx_records": true,
  "username": "user",
  "domain": "example.com",
  "smtp_details": {
    "host_exists": true,
    "full_inbox": false,
    "catch_all": false,
    "deliverable": true,
    "disabled": false
  }
}
```

## What We Check

### 1. Syntax Validation
- Validates email format according to RFC standards
- Parses username and domain components
- Checks for proper structure and characters

### 2. Domain & MX Records
- Verifies domain exists
- Checks for valid Mail Exchange (MX) records
- Ensures domain can receive emails

### 3. SMTP Verification
- Connects to the actual mail server
- Verifies if the specific mailbox exists
- Checks server response codes
- Detects full inboxes and disabled accounts

### 4. Disposable Detection
- Identifies temporary email services
- Auto-updates disposable domain list
- Helps filter out throwaway emails

### 5. Role Account Check
- Detects generic role-based emails
- Common patterns: admin@, support@, info@, noreply@
- Useful for lead qualification

### 6. Free Provider Detection
- Identifies free email services
- Gmail, Yahoo, Outlook, etc.
- Helps distinguish personal vs business emails

### 7. Domain Suggestions
- Detects common typos in domain names
- Suggests corrections (gmail.com instead of gmai.com)
- Improves data quality

## 🚀 GitHub Actions CI/CD

This repository includes a GitHub Actions workflow that:

- ✅ Runs tests on every push and pull request
- 🐳 Builds multi-architecture Docker images (AMD64 + ARM64)
- 📦 Publishes to GitHub Container Registry automatically
- 🏷️ Tags images based on git branches and tags
- ⚡ Uses build caching for faster builds

### Triggering Builds

- **Push to main**: Creates `latest` and `main` tags
- **Create tag**: `git tag v1.0.0 && git push origin v1.0.0` creates versioned tags
- **Pull requests**: Builds images for testing (not published)

### Setting Up Your Repository

1. Fork or create this repository on GitHub
2. Enable GitHub Actions (enabled by default)
3. Ensure repository has "Read and write permissions" for Actions
4. Push code - the workflow will automatically build and publish images

## Configuration

The application uses the following default settings:

- **Port**: 8080
- **SMTP Check**: Enabled
- **Domain Suggestions**: Enabled
- **Auto-update Disposable Domains**: Enabled
- **Catch-all Detection**: Enabled

### Environment Variables

You can customize the application behavior with environment variables:

```bash
# Server port
export PORT=8080

# Enable/disable SMTP checking (true/false)
export ENABLE_SMTP_CHECK=true

# SOCKS5 proxy for SMTP connections (optional)
export PROXY_URI=socks5://user:password@127.0.0.1:1080
```

## SMTP Port 25 Considerations

⚠️ **Important**: Most ISPs block outgoing SMTP requests through port 25 to prevent spam. This means:

- SMTP verification may not work on some networks
- The application might hang or timeout during SMTP checks
- Consider using a VPS or proxy if you need full SMTP verification

If you encounter connection issues, you can:
1. Deploy on a VPS with unrestricted SMTP access
2. Use a SOCKS proxy for SMTP connections
3. Disable SMTP checking (results will be less accurate)

## Project Structure

```
email-verifier/
├── main.go              # Main application server
├── templates/           # HTML templates
│   ├── index.html       # Main page
│   └── result.html      # Results page
├── static/              # Static assets (if needed)
├── go.mod               # Go module file
├── go.sum               # Dependency checksums
└── README.md            # This file
```

## Dependencies

- Go 1.22+ - Required for building and running
- [AfterShip Email Verifier](https://github.com/AfterShip/email-verifier) - Core email verification library
- Go standard library for HTTP server and templating
- [Tailwind CSS](https://tailwindcss.com/) (CDN) - Styling
- [Font Awesome](https://fontawesome.com/) (CDN) - Icons

## API Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `email` | string | The email address that was verified |
| `is_valid` | boolean | Whether the email format is valid |
| `reachable` | string | "yes", "no", or "unknown" |
| `disposable` | boolean | Whether it's a disposable email |
| `role_account` | boolean | Whether it's a role-based account |
| `free` | boolean | Whether it's from a free provider |
| `has_mx_records` | boolean | Whether domain has MX records |
| `username` | string | The username part of the email |
| `domain` | string | The domain part of the email |
| `suggestion` | string | Suggested domain if typo detected |
| `smtp_details` | object | SMTP verification details |
| `error` | string | Error message if verification failed |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- [AfterShip](https://github.com/AfterShip) for the excellent email-verifier library
- [Tailwind CSS](https://tailwindcss.com/) for the beautiful styling framework
- [Font Awesome](https://fontawesome.com/) for the icons

## Support

If you encounter any issues or have questions:

1. Check the [Issues](../../issues) page
2. Review the SMTP port 25 considerations above
3. Create a new issue with detailed information

---

Built with ❤️ using Go and modern web technologies.