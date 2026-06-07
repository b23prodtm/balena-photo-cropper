#!/bin/bash
#
# Complete integration test suite for balena-photo-cropper
# Tests are located in: tests/
#

set -e

# Configuration
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
TESTS_DIR="$(pwd)/tests"
IMAGE_DIR="$TESTS_DIR/images"
BASE_URL="${BASE_URL:-http://127.0.0.1}"
PORT="${PORT:-8080}"
CAKE_PORT="${CAKE_PORT:-9000}"
FLASK_PORT="${FLASK_PORT:-5000}"
TIMEOUT=90

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

# Check tests directory exists
check_tests_dir() {
    log_section "Checking Tests Directory"
    
    if [ ! -d "$TESTS_DIR" ]; then
        log_fail "Tests directory not found: $TESTS_DIR"
        exit 1
    fi
    
    log_pass "Tests directory found: $TESTS_DIR"
    
    # Check test files exist
    local files=(
        "generate_test_images.py"
        "test_cropper_flask.py"
        "test_interactive_cropper.py"
        "test_cakephp_routes.sh"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$TESTS_DIR/$file" ]; then
            log_pass "Found: $file"
        else
            log_fail "Missing: $file"
            exit 1
        fi
    done
}

# Check requirements
check_requirements() {
    log_section "Checking Requirements"
    
    local missing=0
    
    for cmd in python3 docker curl; do
        if command -v $cmd &> /dev/null; then
            log_pass "$cmd found"
        else
            log_fail "$cmd not found"
            missing=1
        fi
    done
    
    [ $missing -eq 0 ] && log_pass "All requirements met" || exit 1
}

# Generate test images
generate_images() {
    log_section "Generating Test Images"
    
    mkdir -p "$IMAGE_DIR"
    
    python3 "$TESTS_DIR/generate_test_images.py" "$IMAGE_DIR"
    
    if [ -f "$IMAGE_DIR/test_image.jpg" ] && \
       [ -f "$IMAGE_DIR/test_image.tiff" ]; then
        log_pass "Test images generated"
        return 0
    else
        log_fail "Failed to generate test images"
        return 1
    fi
}

# build services
build_services() {
    # Config — service names must match docker-compose.yml
    SERVICE1="cropper"
    SERVICE2="nginx"
    SERVICE3="web"
    CONTEXT1="./$SERVICE1"
    CONTEXT2="./$SERVICE2"
    CONTEXT3="./$SERVICE3"
    STATE_FILE=".last_build_sigs"

    sig_for() {
      ctx="$1"
      if [ ! -d "$ctx" ]; then
        echo "absent-$ctx"
        return
      fi
      find "$ctx" -type f ! -path '*/.git/*' -print0 \
        | sort -z \
        | xargs -0 sha256sum 2>/dev/null \
        | sha256sum \
        | awk '{print $1}'
    }

    cur1="$(sig_for "$CONTEXT1")"
    cur2="$(sig_for "$CONTEXT2")"
    cur3="$(sig_for "$CONTEXT3")"

    last1=""; last2=""; last3=""
    if [ -f "$STATE_FILE" ]; then
      IFS=' ' read -r last1 last2 last3 < "$STATE_FILE"
    fi

    changed=""
    [ "$cur1" != "$last1" ] && changed="$changed $SERVICE1"
    [ "$cur2" != "$last2" ] && changed="$changed $SERVICE2"
    [ "$cur3" != "$last3" ] && changed="$changed $SERVICE3"

    if [ -n "$changed" ]; then
      echo "Changes detected for:$changed"
      for svc in $changed; do
        svc=$(echo "$svc" | tr -d ' ')
        echo "Building $svc..."
        docker compose build --no-cache --pull "$svc" || exit 1
      done
      printf "%s %s %s" "$cur1" "$cur2" "$cur3" > "$STATE_FILE"
      echo "Rebuild(s) complete."
    else
      echo "No changes detected for $SERVICE1, $SERVICE2, $SERVICE3. Skipping rebuild."
    fi
}

# Start docker compose
start_services() {
    log_section "Starting Docker Compose Services"
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_fail "docker-compose.yml not found"
        return 1
    fi
    
    log_info "Starting services (timeout: ${TIMEOUT}s)..."
    docker compose -f "$COMPOSE_FILE" up -d --force-recreate
    
    local start_time=$(date +%s)
    while true; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $TIMEOUT ]; then
            log_fail "Services did not start within ${TIMEOUT}s"
            docker compose -f "$COMPOSE_FILE" logs
            return 1
        fi
        
        if curl -f -s -m 1 "$BASE_URL:$FLASK_PORT/health" > /dev/null 2>&1; then
            log_pass "Services are ready"
            sleep 2
            return 0
        fi
        
        echo -n "."
        sleep 2
    done
}

# Run Flask tests
run_flask_tests() {
    log_section "Running Flask API Tests"
    
    echo "Running: python3 $TESTS_DIR/test_cropper_flask.py $BASE_URL:$FLASK_PORT $IMAGE_DIR"
    if python3 "$TESTS_DIR/test_cropper_flask.py" "$BASE_URL:$FLASK_PORT" "$IMAGE_DIR" 2>&1; then
        log_pass "Flask tests passed"
        return 0
    else
        local exit_code=$?
        log_fail "Flask tests failed with exit code: $exit_code"
        return $exit_code
    fi
}

# Run CakePHP tests
run_cakephp_tests() {
    log_section "Running CakePHP Web Tests"
    
    if bash "$TESTS_DIR/test_cakephp_routes.sh" "$BASE_URL:$CAKE_PORT"; then
        log_pass "CakePHP tests passed"
        return 0
    else
        log_fail "CakePHP tests failed"
        return 1
    fi
}

# Run CLI tests
run_cli_tests() {
    log_section "Running CLI Tests"
    
    if [ -f "$TESTS_DIR/tools/interactive_cropper.py" ]; then
        if python3 "$TESTS_DIR/test_interactive_cropper.py" "$IMAGE_DIR"; then
            log_pass "CLI tests passed"
            return 0
        else
            log_fail "CLI tests failed"
            return 1
        fi
    else
        log_info "$TESTS_DIR/tools/interactive_cropper.py not found, skipping CLI tests"
        return 0
    fi
}

# Show logs
show_logs() {
    log_section "Service Logs"
    echo "Recent logs from docker compose:"
    docker compose -f "$COMPOSE_FILE" logs --tail=50
}

# Cleanup
cleanup() {
    log_section "Cleanup"
    docker compose -f "$COMPOSE_FILE" down || true
    log_pass "Services stopped"
}

# Main
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🧪 BALENA-PHOTO-CROPPER INTEGRATION TEST SUITE            ║"
    echo "║                                                            ║"
    echo "║  Tests Flask, CLI, and CakePHP before Balena Cloud        ║"
    echo "║  Tests located in: tests/                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local failed_tests=()
    
    # Step 1: Check tests directory
    check_tests_dir || exit 1
    
    # Step 2: Check requirements
    check_requirements || exit 1
    
    # Step 3: Generate test images
    generate_images || exit 1
    
    # Step 4.a: Rebuild services
    build_services || exit 1

    # Step 4.b: Start services
    start_services || exit 1
    
    # Step 5-7: Run tests (collect failures without exiting)
    set +e  # Don't exit on test failures yet
    run_flask_tests || failed_tests+=("Flask")
    run_cakephp_tests || failed_tests+=("CakePHP")  
    run_cli_tests || failed_tests+=("CLI")
    set -e  # Re-enable exit on error

    # Summary
    log_section "🎯 Final Summary"
    
    if [ ${#failed_tests[@]} -eq 0 ]; then
        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║  🎉 ALL TESTS PASSED!                                     ║"
        echo "║                                                            ║"
        echo "║  ✅ Flask API working                                      ║"
        echo "║  ✅ CakePHP routes working                                 ║"
        echo "║  ✅ CLI tools working                                      ║"
        echo "║                                                            ║"
        echo "║  Ready for deployment to Balena Cloud! 🚀                 ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        cleanup
        return 0
    else
        echo -e "${RED}"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║  ❌ SOME TESTS FAILED                                      ║"
        echo "║                                                            ║"
        printf "║  Failed: %s\n" "${failed_tests[@]}" | head -3
        echo "║                                                            ║"
        echo "║  Check logs above and fix issues                           ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        show_logs
        cleanup
        return 1
    fi
}

# Run main
main
exit $?