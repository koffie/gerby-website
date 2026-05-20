#!/usr/bin/env bash
# test_endpoints.sh — smoke-test all GET and POST endpoints of the gerby website.
#
# Usage: ./test_endpoints.sh [--dev] [HOST]
#
#   --dev   Also run the POST /post-comment test with a valid email.
#                     WARNING: this writes a real comment to the database.
#                     Requires TEST_EMAIL to be set.
#   HOST              Base URL, defaults to http://localhost:8080
#
# Sample values for parametrised routes can be overridden via env vars:
#   TAG=0001 BIBKEY=sga4 CHAPTER=1 TEX_FILE=preamble.tex PDF_FILE=book.pdf
#   TEST_EMAIL=you@example.com  (used when --dev is given, defaults to you@example.com)

set -euo pipefail

# ----------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------
HOST="http://localhost:8080"
WRITE_COMMENT=false

for arg in "$@"; do
  case "${arg}" in
    --dev) WRITE_COMMENT=true ;;
    http://*|https://*) HOST="${arg}" ;;
    *) echo "Unknown argument: ${arg}" >&2; exit 1 ;;
  esac
done

HOST="${HOST%/}"          # strip trailing slash

TEST_EMAIL="${TEST_EMAIL:-you@example.com}"

# --- sample values for parametrised routes (override via env) ---
TAG="${TAG:-0001}"
BIBKEY="${BIBKEY:-Euclid}"
CHAPTER="${CHAPTER:-1}"
TEX_FILE="${TEX_FILE:-preamble.tex}"
PDF_FILE="${PDF_FILE:-book.pdf}"

# ----------------------------------------------------------------
# Known-failing GET endpoints (reported as WARN, not FAIL).
# Edit this list as endpoints are fixed or newly broken.
# ----------------------------------------------------------------
KNOWN_FAILING=(
  "/download/${PDF_FILE}"
)

# ----------------------------------------------------------------
# All GET endpoints.  Parametrised paths use the sample values above.
# ----------------------------------------------------------------
ENDPOINTS=(
  # General
  "/"
  "/about"
  "/statistics"
  "/browse"
  "/robots.txt"

  # Tags
  "/tag/${TAG}"
  "/tag/tag/${TAG}"
  "/tag/${TAG}/cite"
  "/tag/${TAG}/statistics"
  "/tag/${TAG}/history"
  "/index.php"
  "/tags"

  # Graphs
  # Search
  "/search"
  "/tag"

  # Bibliography
  "/bibliography"
  "/bibliography/${BIBKEY}"

  # Comments
  "/recent-comments"
  "/recent-comments/1"
  "/recent-comments.xml"
  "/recent-comments.rss"

  # Stacks Project Specific
  "/todo"
  "/markdown"
  "/acknowledgements"
  "/contribute"
  "/contributors"
  "/recent-changes"
  "/chapter/${CHAPTER}"
  "/tex"
  "/tex/${TEX_FILE}"
  "/download/${PDF_FILE}"

  # API (JSON)
  "/api"
  "/data/tag/${TAG}/structure"
  "/data/tag/${TAG}/content/statement"
  "/data/tag/${TAG}/content/full"
  "/data/tag/${TAG}/graph/topics"
  "/data/tag/${TAG}/graph/structure"
  "/data/tag/${TAG}/graph/tree"
)

# ----------------------------------------------------------------
# Test runner
# ----------------------------------------------------------------
PASS=0
WARN=0
FAIL=0
WARNED_ENDPOINTS=()
FAILED_ENDPOINTS=()

# Colour codes (disabled when not a terminal)
if [ -t 1 ]; then
  GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; RESET="\033[0m"; BOLD="\033[1m"
else
  GREEN=""; YELLOW=""; RED=""; RESET=""; BOLD=""
fi

# Returns 0 if the given path is in KNOWN_FAILING, 1 otherwise.
is_known_failing() {
  local path="$1"
  for known in "${KNOWN_FAILING[@]}"; do
    [[ "${known}" == "${path}" ]] && return 0
  done
  return 1
}

echo -e "${BOLD}Testing ${#ENDPOINTS[@]} endpoints against ${HOST}${RESET}"
echo "-----------------------------------------------------------"

for path in "${ENDPOINTS[@]}"; do
  url="${HOST}${path}"

  # -s  silent  -o /dev/null  discard body  -w  write HTTP status code
  # -L  follow redirects  --max-redirs 5
  # --connect-timeout 10  --max-time 30
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -L --max-redirs 5 \
    --connect-timeout 10 --max-time 30 \
    "${url}" 2>/dev/null) || http_code="000"

  if [[ "${http_code}" =~ ^[23] ]]; then
    echo -e "  ${GREEN}PASS${RESET} [${http_code}]  ${url}"
    (( PASS++ )) || true
  elif is_known_failing "${path}"; then
    echo -e "  ${YELLOW}WARN${RESET} [${http_code}]  ${url}  (known failure)"
    WARNED_ENDPOINTS+=("${url}  (HTTP ${http_code})")
    (( WARN++ )) || true
  else
    echo -e "  ${RED}FAIL${RESET} [${http_code}]  ${url}"
    FAILED_ENDPOINTS+=("${url}  (HTTP ${http_code})")
    (( FAIL++ )) || true
  fi
done

# ----------------------------------------------------------------
# POST endpoints
# ----------------------------------------------------------------
echo ""
echo -e "${BOLD}POST endpoints${RESET}"
echo "-----------------------------------------------------------"

post_url="${HOST}/post-comment"

# --- invalid email (always runs) ---
# Passes the captcha but supplies an invalid email so no comment is written
# to the database.  Expects a 200 "invalid email" page.
invalid_code=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Referer: ${HOST}/tag/${TAG}" \
  --data-urlencode "tag=${TAG}" \
  --data-urlencode "check=${TAG}" \
  --data-urlencode "name=smoke-test" \
  --data-urlencode "mail=not-a-valid-email" \
  --data-urlencode "site=" \
  --data-urlencode "comment=smoke test" \
  --connect-timeout 10 --max-time 30 \
  "${post_url}" 2>/dev/null) || invalid_code="000"

if [[ "${invalid_code}" =~ ^[23] ]]; then
  echo -e "  ${GREEN}PASS${RESET} [${invalid_code}]  ${post_url}  (invalid email)"
  (( PASS++ )) || true
else
  echo -e "  ${RED}FAIL${RESET} [${invalid_code}]  ${post_url}  (invalid email)"
  FAILED_ENDPOINTS+=("${post_url} (invalid email)  (HTTP ${invalid_code})")
  (( FAIL++ )) || true
fi

# --- valid email (only with --dev) ---
# Passes the captcha with a real email address and WILL write a comment to
# the database.  Expects a 302 redirect to the tag page.
if [[ "${WRITE_COMMENT}" == true ]]; then
  valid_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Referer: ${HOST}/tag/${TAG}" \
    --data-urlencode "tag=${TAG}" \
    --data-urlencode "check=${TAG}" \
    --data-urlencode "name=smoke-test" \
    --data-urlencode "mail=${TEST_EMAIL}" \
    --data-urlencode "site=" \
    --data-urlencode "comment=smoke test (automated, please delete)" \
    --connect-timeout 10 --max-time 30 \
    "${post_url}" 2>/dev/null) || valid_code="000"

  if [[ "${valid_code}" =~ ^[23] ]]; then
    echo -e "  ${GREEN}PASS${RESET} [${valid_code}]  ${post_url}  (valid email — comment written to DB)"
    (( PASS++ )) || true
  else
    echo -e "  ${RED}FAIL${RESET} [${valid_code}]  ${post_url}  (valid email)"
    FAILED_ENDPOINTS+=("${post_url} (valid email)  (HTTP ${valid_code})")
    (( FAIL++ )) || true
  fi
fi

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
echo "-----------------------------------------------------------"
TOTAL=$(( PASS + WARN + FAIL ))
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}  ${YELLOW}${WARN} warned${RESET}  ${RED}${FAIL} failed${RESET}  (total ${TOTAL})"

if (( WARN > 0 )); then
  echo -e "\n${BOLD}${YELLOW}Known failing endpoints:${RESET}"
  for entry in "${WARNED_ENDPOINTS[@]}"; do
    echo "  - ${entry}"
  done
fi

if (( FAIL > 0 )); then
  echo -e "\n${BOLD}${RED}Failed endpoints:${RESET}"
  for entry in "${FAILED_ENDPOINTS[@]}"; do
    echo "  - ${entry}"
  done
  exit 1
fi

echo -e "${GREEN}All endpoints OK.${RESET}"
exit 0
