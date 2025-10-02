#!/bin/bash

# Email Verifier API Test Script
# Usage: ./test_email.sh [email] [port]

# Default values
DEFAULT_EMAIL="test@gmail.com"
DEFAULT_PORT="8080"

# Use provided arguments or defaults
EMAIL=${1:-$DEFAULT_EMAIL}
PORT=${2:-$DEFAULT_PORT}
API_URL="http://localhost:${PORT}/api/verify"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Email Verifier API Test${NC}"
echo -e "${BLUE}=========================${NC}"
echo -e "Testing email: ${YELLOW}${EMAIL}${NC}"
echo -e "API endpoint: ${YELLOW}${API_URL}${NC}"
echo ""

# Check if server is running
echo -e "${BLUE}📡 Checking if server is running...${NC}"
if ! curl -s -f "http://localhost:${PORT}/" > /dev/null; then
    echo -e "${RED}❌ Server is not running on port ${PORT}${NC}"
    echo -e "${YELLOW}💡 Start the server with: go run main.go${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Server is running${NC}"
echo ""

# Test the API
echo -e "${BLUE}🔍 Testing email verification...${NC}"
RESPONSE=$(curl -s -X POST "${API_URL}" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${EMAIL}\"}" \
    -w "HTTP_STATUS:%{http_code}")

# Extract HTTP status and response body
HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

echo -e "${BLUE}HTTP Status:${NC} ${HTTP_STATUS}"

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✅ API request successful${NC}"
    echo ""
    echo -e "${BLUE}📊 Response:${NC}"
    echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}❌ API request failed${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE_BODY"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 Parsing results...${NC}"

# Parse JSON response (requires jq for better parsing, falls back to grep)
if command -v jq > /dev/null 2>&1; then
    IS_VALID=$(echo "$RESPONSE_BODY" | jq -r '.is_valid // "unknown"')
    REACHABLE=$(echo "$RESPONSE_BODY" | jq -r '.reachable // "unknown"')
    DISPOSABLE=$(echo "$RESPONSE_BODY" | jq -r '.disposable // "unknown"')
    ROLE_ACCOUNT=$(echo "$RESPONSE_BODY" | jq -r '.role_account // "unknown"')
    FREE=$(echo "$RESPONSE_BODY" | jq -r '.free // "unknown"')
    HAS_MX=$(echo "$RESPONSE_BODY" | jq -r '.has_mx_records // "unknown"')
    SUGGESTION=$(echo "$RESPONSE_BODY" | jq -r '.suggestion // ""')
    ERROR_MSG=$(echo "$RESPONSE_BODY" | jq -r '.error // ""')
else
    # Fallback parsing without jq
    IS_VALID=$(echo "$RESPONSE_BODY" | grep -o '"is_valid":[^,}]*' | cut -d: -f2 | tr -d ' "')
    REACHABLE=$(echo "$RESPONSE_BODY" | grep -o '"reachable":"[^"]*"' | cut -d: -f2 | tr -d '"')
    DISPOSABLE=$(echo "$RESPONSE_BODY" | grep -o '"disposable":[^,}]*' | cut -d: -f2 | tr -d ' ')
    ROLE_ACCOUNT=$(echo "$RESPONSE_BODY" | grep -o '"role_account":[^,}]*' | cut -d: -f2 | tr -d ' ')
    FREE=$(echo "$RESPONSE_BODY" | grep -o '"free":[^,}]*' | cut -d: -f2 | tr -d ' ')
    HAS_MX=$(echo "$RESPONSE_BODY" | grep -o '"has_mx_records":[^,}]*' | cut -d: -f2 | tr -d ' ')
    SUGGESTION=$(echo "$RESPONSE_BODY" | grep -o '"suggestion":"[^"]*"' | cut -d: -f2 | tr -d '"')
    ERROR_MSG=$(echo "$RESPONSE_BODY" | grep -o '"error":"[^"]*"' | cut -d: -f2 | tr -d '"')
fi

# Display results with colors
echo ""
echo -e "${BLUE}📋 Summary for ${YELLOW}${EMAIL}${NC}:"
echo -e "${BLUE}================================${NC}"

if [ "$ERROR_MSG" != "" ]; then
    echo -e "❌ Error: ${RED}${ERROR_MSG}${NC}"
else
    # Valid format
    if [ "$IS_VALID" = "true" ]; then
        echo -e "✅ Valid format: ${GREEN}Yes${NC}"
    else
        echo -e "❌ Valid format: ${RED}No${NC}"
    fi

    # Reachability
    case "$REACHABLE" in
        "yes")
            echo -e "📡 Reachable: ${GREEN}Yes${NC}"
            ;;
        "no")
            echo -e "📡 Reachable: ${RED}No${NC}"
            ;;
        *)
            echo -e "📡 Reachable: ${YELLOW}Unknown${NC}"
            ;;
    esac

    # MX Records
    if [ "$HAS_MX" = "true" ]; then
        echo -e "🌐 MX Records: ${GREEN}Found${NC}"
    else
        echo -e "🌐 MX Records: ${RED}Not Found${NC}"
    fi

    # Disposable
    if [ "$DISPOSABLE" = "true" ]; then
        echo -e "🗑️  Disposable: ${YELLOW}Yes${NC}"
    else
        echo -e "🗑️  Disposable: ${GREEN}No${NC}"
    fi

    # Role Account
    if [ "$ROLE_ACCOUNT" = "true" ]; then
        echo -e "👔 Role Account: ${YELLOW}Yes${NC}"
    else
        echo -e "👔 Role Account: ${GREEN}No${NC}"
    fi

    # Free Provider
    if [ "$FREE" = "true" ]; then
        echo -e "🆓 Free Provider: ${BLUE}Yes${NC}"
    else
        echo -e "🆓 Free Provider: ${GREEN}No${NC}"
    fi

    # Suggestion
    if [ "$SUGGESTION" != "" ]; then
        echo -e "💡 Suggestion: ${YELLOW}${SUGGESTION}${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Test completed!${NC}"

# Test multiple emails if no specific email was provided
if [ "$EMAIL" = "$DEFAULT_EMAIL" ] && [ $# -eq 0 ]; then
    echo ""
    echo -e "${BLUE}🔄 Running additional tests...${NC}"
    echo ""

    TEST_EMAILS=(
        "invalid-email"
        "admin@example.com"
        "user@nonexistentdomain12345.com"
        "test@gmail.com"
    )

    for test_email in "${TEST_EMAILS[@]}"; do
        echo -e "${BLUE}Testing: ${YELLOW}${test_email}${NC}"
        QUICK_RESPONSE=$(curl -s -X POST "${API_URL}" \
            -H "Content-Type: application/json" \
            -d "{\"email\": \"${test_email}\"}")

        if command -v jq > /dev/null 2>&1; then
            QUICK_VALID=$(echo "$QUICK_RESPONSE" | jq -r '.is_valid // false')
            QUICK_ERROR=$(echo "$QUICK_RESPONSE" | jq -r '.error // ""')
        else
            QUICK_VALID=$(echo "$QUICK_RESPONSE" | grep -o '"is_valid":[^,}]*' | cut -d: -f2 | tr -d ' ')
            QUICK_ERROR=$(echo "$QUICK_RESPONSE" | grep -o '"error":"[^"]*"' | cut -d: -f2 | tr -d '"')
        fi

        if [ "$QUICK_ERROR" != "" ]; then
            echo -e "  ${RED}❌ ${QUICK_ERROR}${NC}"
        elif [ "$QUICK_VALID" = "true" ]; then
            echo -e "  ${GREEN}✅ Valid${NC}"
        else
            echo -e "  ${RED}❌ Invalid${NC}"
        fi
        echo ""
    done
fi

echo -e "${BLUE}💻 Usage examples:${NC}"
echo -e "  ./test_email.sh                           # Test default email"
echo -e "  ./test_email.sh user@example.com          # Test specific email"
echo -e "  ./test_email.sh user@example.com 8080     # Test with custom port"
echo ""
echo -e "${BLUE}🌐 Web interface:${NC} http://localhost:${PORT}"
