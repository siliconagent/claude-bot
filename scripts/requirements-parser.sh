#!/bin/bash
# requirements-parser.sh - Parse requirements and generate acceptance criteria

set -e

REQUIREMENTS_STATE="${STATE_DIR:-.claude}/claude-bot.requirements.yaml"

# Initialize requirements state
req-init() {
    if [[ ! -f "$REQUIREMENTS_STATE" ]]; then
        mkdir -p "$(dirname "$REQUIREMENTS_STATE")"
        cat > "$REQUIREMENTS_STATE" << 'EOF'
# Requirements State for Claude-Bot
version: "2.0"
requirements: []
acceptance_criteria: []
test_cases: []
EOF
    fi
}

# Parse requirements from user request
# Usage: req-parse "user_request_text"
req-parse() {
    local user_request="$1"

    req-init

    echo "# Parsing Requirements"
    echo "Input: $user_request"
    echo ""

    # Extract functional requirements (keywords: should, must, will, need to)
    echo "Functional Requirements:"
    echo "$user_request" | grep -ioE "(should|must|will|need to) [^.!?\.]+" | nl -w2 -s'. ' || echo "  None explicitly stated"

    # Extract non-functional requirements (keywords: fast, secure, scalable, reliable)
    echo ""
    echo "Non-Functional Requirements:"
    echo "$user_request" | grep -ioE "(fast|secure|scalable|reliable|performant|responsive)" | sort -u | nl -w2 -s'. ' || echo "  None explicitly stated"

    # Generate requirement IDs
    local req_counter=1
    while IFS= read -r line; do
        local req_id="req-$(printf "%02d" $req_counter)"
        echo "$req_id: $line"
        req_counter=$((req_counter + 1))
    done < <(echo "$user_request" | grep -iE "(The app should|I want|It needs to)" | nl)
}

# Generate acceptance criteria for a requirement
# Usage: req-generate-criteria "requirement_id" "requirement_text"
req-generate-criteria() {
    local req_id="$1"
    local req_text="$2"

    req-init

    echo "# Acceptance Criteria for $req_id"
    echo "Requirement: $req_text"
    echo ""

    # Generate criteria based on requirement type
    if echo "$req_text" | grep -iqE "login|auth|token|jwt"; then
        cat << 'EOF'
  - AC-1: Login endpoint exists and returns valid JWT
    - Test: POST /login with {email, password}
    - Expected: 200 status with JWT token
    - Status: pending

  - AC-2: Invalid credentials return 401
    - Test: POST /login with invalid credentials
    - Expected: 401 Unauthorized
    - Status: pending

  - AC-3: JWT token validates protected routes
    - Test: GET /protected with valid token
    - Expected: 200 with resource data
    - Status: pending
EOF
    elif echo "$req_text" | grep -iqE "create|add|post|insert"; then
        cat << 'EOF'
  - AC-1: Creation endpoint accepts valid data
    - Test: POST /resource with valid payload
    - Expected: 201 Created with resource ID
    - Status: pending

  - AC-2: Validation rejects invalid data
    - Test: POST /resource with invalid payload
    - Expected: 400 Bad Request with error details
    - Status: pending

  - AC-3: Resource persists in database
    - Test: Query database after creation
    - Expected: Record exists with correct data
    - Status: pending
EOF
    elif echo "$req_text" | grep -iqE "list|get|fetch|read"; then
        cat << 'EOF'
  - AC-1: List endpoint returns all resources
    - Test: GET /resources
    - Expected: 200 with array of resources
    - Status: pending

  - AC-2: Pagination works correctly
    - Test: GET /resources?page=1&limit=10
    - Expected: Returns first 10 resources
    - Status: pending

  - AC-3: Filtering by criteria works
    - Test: GET /resources?filter=value
    - Expected: Returns only matching resources
    - Status: pending
EOF
    else
        cat << 'EOF'
  - AC-1: Feature is accessible
    - Test: Access the feature
    - Expected: Feature loads without errors
    - Status: pending

  - AC-2: Feature behaves correctly
    - Test: Use the feature as intended
    - Expected: Expected outcome occurs
    - Status: pending

  - AC-3: Edge cases are handled
    - Test: Test boundary conditions
    - Expected: Graceful handling or appropriate error
    - Status: pending
EOF
    fi
}

# Validate requirements against implementation
# Usage: req-validate "requirements_list"
req-validate() {
    req-init

    echo "# Requirements Validation"
    echo ""

    # Check each requirement
    local req_counter=1
    while IFS= read -r req_line; do
        local req_id="req-$(printf "%02d" $req_counter)"
        echo "  $req_id: $req_line"

        # Check if related code exists
        local feature_keyword
        feature_keyword=$(echo "$req_line" | grep -oE "\w+" | head -1)

        local matching_files
        matching_files=$(grep -rl "$feature_keyword" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | wc -l | tr -d ' ')

        if [[ $matching_files -gt 0 ]]; then
            echo "    Status: ✅ Implementation found ($matching_files files)"
        else
            echo "    Status: ⚠️  No implementation found"
        fi

        req_counter=$((req_counter + 1))
    done
}

# Generate test cases for requirements
# Usage: req-generate-tests "requirement_id"
req-generate-tests() {
    local req_id="$1"

    req-init

    echo "# Test Cases for $req_id"
    echo ""

    cat << 'EOF'
## Test Case 1: Happy Path
- Description: Verify feature works as expected with valid input
- Pre-conditions: System is running, user is authenticated
- Test Steps:
  1. Navigate to feature
  2. Provide valid input
  3. Submit request
- Expected Result: Feature completes successfully
- Status: pending

## Test Case 2: Error Handling
- Description: Verify feature handles invalid input gracefully
- Pre-conditions: System is running
- Test Steps:
  1. Navigate to feature
  2. Provide invalid input
  3. Submit request
- Expected Result: Appropriate error message displayed
- Status: pending

## Test Case 3: Edge Case
- Description: Verify feature handles boundary conditions
- Pre-conditions: System is running
- Test Steps:
  1. Test with minimum/maximum values
  2. Test with empty/null values
  3. Test with concurrent requests
- Expected Result: Feature handles all cases correctly
- Status: pending
EOF
}

# Check requirement completeness
# Usage: req-check-completeness
req-check-completeness() {
    req-init

    echo "# Requirements Completeness Check"
    echo ""

    local checks=(
        "Functional requirements defined"
        "Non-functional requirements defined"
        "Acceptance criteria exist"
        "Test cases exist"
        "Success metrics defined"
    )

    for check in "${checks[@]}"; do
        echo "  ☐ $check"
    done

    echo ""
    echo "Completeness: $(echo "${#checks[@]}") checks defined"
}

# Export requirements to various formats
# Usage: req-export [format]
req-export() {
    local format="${1:-yaml}"

    req-init

    case "$format" in
        yaml)
            cat "$REQUIREMENTS_STATE"
            ;;
        json)
            # Convert YAML to JSON (requires yq or similar)
            echo '{"format":"json","data":"Install yq for JSON export"}'
            ;;
        markdown)
            echo "# Requirements Document"
            echo ""
            grep -A 10 "^requirements:" "$REQUIREMENTS_STATE" || echo "No requirements defined"
            ;;
        *)
            echo "Unknown format: $format"
            echo "Supported: yaml, json, markdown"
            ;;
    esac
}

# Main command router
case "${1:-}" in
    init)              req-init ;;
    parse)             req-parse "$2" ;;
    generate-criteria) req-generate-criteria "$2" "$3" ;;
    validate)          req-validate "$2" ;;
    generate-tests)    req-generate-tests "$2" ;;
    check-completeness) req-check-completeness ;;
    export)            req-export "$2" ;;
    *)
        echo "Usage: $0 {init|parse|generate-criteria|validate|generate-tests|check-completeness|export}"
        exit 1
        ;;
esac
