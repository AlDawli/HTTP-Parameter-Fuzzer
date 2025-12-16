#!/bin/bash

# HTTP Parameter Fuzzer v1.0
# A simple but powerful parameter discovery tool

VERSION="1.0.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   HTTP Parameter Fuzzer v${VERSION}      ║"
    echo "║   Simple Parameter Discovery Tool     ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -u, --url URL          Target URL (required)
    -w, --wordlist FILE    Wordlist file (default: built-in common params)
    -m, --method METHOD    HTTP method (GET/POST) (default: GET)
    -j, --js-extract URL   Extract parameters from JS file
    -r, --reflect          Highlight parameter reflections (XSS testing)
    -t, --threads NUM      Number of concurrent threads (default: 10)
    -d, --delay NUM        Delay between requests in seconds (default: 0)
    -o, --output FILE      Output results to file
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Basic parameter fuzzing
    $0 -u "https://example.com/api/user" -w params.txt

    # Test with reflection detection
    $0 -u "https://example.com/search" -r

    # Extract and test parameters from JS file
    $0 -u "https://example.com/api" -j "https://example.com/app.js"

    # POST method with custom wordlist
    $0 -u "https://example.com/api" -m POST -w custom.txt

EOF
}

# Built-in common parameters
get_common_params() {
    cat << 'EOF'
id
user
username
name
email
token
key
api_key
apikey
access_token
search
q
query
page
limit
offset
sort
order
category
type
status
filter
callback
redirect
url
file
path
debug
test
admin
password
pass
auth
session
csrf
action
cmd
command
code
lang
language
format
view
mode
theme
version
data
value
param
parameter
input
output
next
prev
ref
return
from
to
EOF
}

# Parse command line arguments
parse_args() {
    URL=""
    WORDLIST=""
    METHOD="GET"
    JS_FILE=""
    REFLECT=false
    THREADS=10
    DELAY=0
    OUTPUT=""
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                URL="$2"
                shift 2
                ;;
            -w|--wordlist)
                WORDLIST="$2"
                shift 2
                ;;
            -m|--method)
                METHOD="${2^^}"
                shift 2
                ;;
            -j|--js-extract)
                JS_FILE="$2"
                shift 2
                ;;
            -r|--reflect)
                REFLECT=true
                shift
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            -d|--delay)
                DELAY="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "$URL" ]]; then
        echo -e "${RED}[!] Error: URL is required${NC}"
        show_help
        exit 1
    fi
}

# Extract parameters from JavaScript file
extract_from_js() {
    local js_url="$1"
    echo -e "${BLUE}[*] Extracting parameters from JS file...${NC}"
    
    local js_content=$(curl -s "$js_url" 2>/dev/null)
    
    if [[ -z "$js_content" ]]; then
        echo -e "${RED}[!] Failed to fetch JS file${NC}"
        return 1
    fi
    
    # Extract potential parameters using various patterns
    echo "$js_content" | grep -oP '["'\'']\K[a-zA-Z_][a-zA-Z0-9_]{2,20}(?=["'\''])' | sort -u
    echo "$js_content" | grep -oP '\?[a-zA-Z_][a-zA-Z0-9_]*=' | sed 's/[?=]//g' | sort -u
    echo "$js_content" | grep -oP '&[a-zA-Z_][a-zA-Z0-9_]*=' | sed 's/[&=]//g' | sort -u
}

# Test a single parameter
test_parameter() {
    local param="$1"
    local test_value="fuzz_test_$$"
    local test_url=""
    
    # Add separator if URL already has parameters
    if [[ "$URL" == *"?"* ]]; then
        test_url="${URL}&${param}=${test_value}"
    else
        test_url="${URL}?${param}=${test_value}"
    fi
    
    # Make request based on method
    if [[ "$METHOD" == "POST" ]]; then
        response=$(curl -s -w "\n%{http_code}" -X POST -d "${param}=${test_value}" "$URL" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" "$test_url" 2>/dev/null)
    fi
    
    # Extract status code (last line)
    status_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    
    # Check for reflection
    reflection=""
    if [[ "$REFLECT" == true ]] && echo "$body" | grep -q "$test_value"; then
        reflection=" ${YELLOW}[REFLECTED]${NC}"
    fi
    
    # Categorize response
    case $status_code in
        200)
            echo -e "${GREEN}[200] ${param}${reflection}${NC}"
            [[ -n "$OUTPUT" ]] && echo "[200] $param $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT"
            ;;
        3[0-9][0-9])
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${CYAN}[${status_code}] ${param}${NC}"
            fi
            ;;
        4[0-9][0-9])
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${YELLOW}[${status_code}] ${param}${NC}"
            fi
            ;;
        5[0-9][0-9])
            echo -e "${RED}[${status_code}] ${param}${NC}"
            [[ -n "$OUTPUT" ]] && echo "[${status_code}] $param $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT"
            ;;
        *)
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${MAGENTA}[${status_code}] ${param}${NC}"
            fi
            ;;
    esac
    
    # Delay between requests
    if [[ "$DELAY" -gt 0 ]]; then
        sleep "$DELAY"
    fi
}

# Export function for parallel execution
export -f test_parameter
export URL METHOD REFLECT VERBOSE DELAY OUTPUT RED GREEN YELLOW BLUE MAGENTA CYAN NC

# Main fuzzing function
fuzz_parameters() {
    local params_file="$1"
    local total=$(wc -l < "$params_file")
    
    echo -e "${BLUE}[*] Starting parameter fuzzing...${NC}"
    echo -e "${BLUE}[*] Target: ${URL}${NC}"
    echo -e "${BLUE}[*] Method: ${METHOD}${NC}"
    echo -e "${BLUE}[*] Total parameters: ${total}${NC}"
    echo -e "${BLUE}[*] Threads: ${THREADS}${NC}"
    echo ""
    
    # Use parallel processing if available, otherwise sequential
    if command -v xargs &> /dev/null; then
        cat "$params_file" | xargs -P "$THREADS" -I {} bash -c 'test_parameter "$@"' _ {}
    else
        while IFS= read -r param; do
            test_parameter "$param"
        done < "$params_file"
    fi
}

# Main execution
main() {
    show_banner
    parse_args "$@"
    
    # Create temporary wordlist
    TEMP_WORDLIST=$(mktemp)
    trap "rm -f $TEMP_WORDLIST" EXIT
    
    # Build wordlist
    if [[ -n "$WORDLIST" ]]; then
        if [[ ! -f "$WORDLIST" ]]; then
            echo -e "${RED}[!] Wordlist file not found: $WORDLIST${NC}"
            exit 1
        fi
        cat "$WORDLIST" > "$TEMP_WORDLIST"
    else
        get_common_params > "$TEMP_WORDLIST"
    fi
    
    # Extract parameters from JS file if provided
    if [[ -n "$JS_FILE" ]]; then
        extract_from_js "$JS_FILE" >> "$TEMP_WORDLIST"
    fi
    
    # Remove duplicates and empty lines
    sort -u "$TEMP_WORDLIST" | grep -v '^$' > "${TEMP_WORDLIST}.clean"
    mv "${TEMP_WORDLIST}.clean" "$TEMP_WORDLIST"
    
    # Initialize output file
    if [[ -n "$OUTPUT" ]]; then
        echo "# HTTP Parameter Fuzzer Results - $(date)" > "$OUTPUT"
        echo "# Target: $URL" >> "$OUTPUT"
        echo "" >> "$OUTPUT"
    fi
    
    # Start fuzzing
    fuzz_parameters "$TEMP_WORDLIST"
    
    echo ""
    echo -e "${GREEN}[✓] Fuzzing complete!${NC}"
    [[ -n "$OUTPUT" ]] && echo -e "${GREEN}[✓] Results saved to: ${OUTPUT}${NC}"
}

main "$@"