# Email Verifier

A Go web application for email verification without sending emails, built with [AfterShip Email Verifier](https://github.com/AfterShip/email-verifier).

## Features

- **Validation**: Syntax, MX records, SMTP checks, and domain typos.
- **Detection**: Disposable emails, role accounts, and free providers.
- **Interfaces**: Modern responsive UI and JSON API.

## Quick Start

Requires Go 1.22+.

```bash
git clone <repository-url>
cd email-verifier
go mod tidy
go run main.go
```

Open `http://localhost:8081` in your browser.

## Docker

Run using the pre-built image from GHCR:

```bash
docker run -p 8081:8081 ghcr.io/yourusername/email-verifier:latest
```

## API Usage

```bash
curl -X POST http://localhost:8081/api/verify \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

**Response:**
```json
{
  "email": "user@example.com",
  "is_valid": true,
  "reachable": "unknown",
  "disposable": false,
  "role_account": false,
  "free": false,
  "has_mx_records": true,
  "smtp_details": { ... }
}
```

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `PORT` | 8081 | Application port |
| `ENABLE_SMTP_CHECK` | true | Perform SMTP server lookup |
| `PROXY_URI` | - | SOCKS5 proxy URL (optional) |

### ⚠️ SMTP Port 25 Warning
Most residential ISPs block port 25. SMTP verification may fail or hang locally. For best results, deploy on a VPS or use a SOCKS proxy.

## License

[MIT License](LICENSE).