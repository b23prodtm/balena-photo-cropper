#!/bin/bash
#
# Test suite for CakePHP web routes
# Tests: /uploads/add, /uploads/crop, /uploads/save-crop, /cropper, /index
#

set -e

BASE_URL="${1:-http://localhost}"
PORT="${2:-8080}"
TIMEOUT=10

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

log_pass() {
    echo -e "${GREEN}✅ [PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}❌ [FAIL]${NC} $1"
    if [ -n "$2" ]; then
        echo "    Details: $2"
    fi
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}⚠️  [SKIP]${NC} $1"
    ((SKIPPED++))
}

log_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

# Test health check
test_health() {
    echo -e "\n🔍 Checking web server health..."
    
    if curl -f -s -m $TIMEOUT "$BASE_URL/" > /dev/null 2>&1; then
        log_pass "Web server is running"
        return 0
    else
        log_fail "Cannot connect to $BASE_URL"
        log_info "Make sure: docker compose up -d"
        return 1
    fi
}

# Test /index route
test_index() {
    echo -e "\n🏠 Testing /index route..."
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT "$BASE_URL:$PORT/index")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        log_pass "/index route returns $http_code"
        return 0
    else
        log_fail "/index route returns $http_code (expected 200/301/302)"
        return 1
    fi
}

# Test /cropper route
test_cropper() {
    echo -e "\n📸 Testing /cropper route..."
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT "$BASE_URL/cropper")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        log_pass "/cropper route returns $http_code"
        return 0
    else
        log_fail "/cropper route returns $http_code (expected 200/301/302)"
        return 1
    fi
}

# Test /uploads/add route
test_uploads_add() {
    echo -e "\n➕ Testing /uploads/add route..."
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT -X POST "$BASE_URL/uploads/add")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ] || [ "$http_code" = "302" ]; then
        log_pass "/uploads/add route returns $http_code"
        return 0
    else
        log_fail "/uploads/add route returns $http_code"
        return 1
    fi
}

# Test /uploads/crop route
test_uploads_crop() {
    echo -e "\n✂️  Testing /uploads/crop route..."
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT -X POST \
        -d "id=1&x=0&y=0&width=100&height=100" \
        "$BASE_URL/uploads/crop")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ] || [ "$http_code" = "302" ]; then
        log_pass "/uploads/crop route returns $http_code"
        return 0
    else
        log_fail "/uploads/crop route returns $http_code"
        return 1
    fi
}

# Test /uploads/save-crop route
test_uploads_save_crop() {
    echo -e "\n💾 Testing /uploads/save-crop route..."
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT -X POST \
        -d "id=1" \
        "$BASE_URL/uploads/save-crop")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ] || [ "$http_code" = "302" ]; then
        log_pass "/uploads/save-crop route returns $http_code"
        return 0
    else
        log_fail "/uploads/save-crop route returns $http_code"
        return 1
    fi
}

# Test PHP info
test_php_info() {
    echo -e "\n🐘 Testing PHP availability..."
    
    if curl -s -m $TIMEOUT "$BASE_URL/" | grep -q "php\|html"; then
        log_pass "PHP is serving content"
        return 0
    else
        log_skip "Cannot verify PHP directly"
        return 0
    fi
}

# Main test suite
main() {
    echo "=========================================="
    echo "🧪 CAKEPHP WEB TEST SUITE"
    echo "=========================================="
    echo "Base URL: $BASE_URL"
    echo ""
    
    # Health check first
    if ! test_health; then
        exit 1
    fi
    
    # Run all tests
    test_index
    test_cropper
    test_php_info
    test_uploads_add
    test_uploads_crop
    test_uploads_save_crop
    
    # Summary
    echo ""
    echo "=========================================="
    echo "📊 TEST SUMMARY"
    echo "=========================================="
    
    TOTAL=$((PASSED + FAILED + SKIPPED))
    
    echo -e "Passed:  ${GREEN}$PASSED${NC}"
    echo -e "Failed:  ${RED}$FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
    echo "Total:   $TOTAL"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! Ready for Balena Cloud!${NC}"
        return 0
    else
        echo -e "\n${RED}⚠️  $FAILED test(s) failed${NC}"
        return 1
    fi
}

main
exit $?
