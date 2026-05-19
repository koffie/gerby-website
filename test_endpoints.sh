#!/usr/bin/env bash
# test_endpoints.sh — smoke-test all GET endpoints of the gerby website.
# Usage: ./test_endpoints.sh [HOST]
#   HOST defaults to http://localhost:8080
#
# Sample values for parametrised routes can be overridden via env vars:
#   TAG=0001 BIBKEY=sga4 CHAPTER=1 TEX_FILE=preamble.tex PDF_FILE=book.pdf

set -euo pipefail

HOST="${1:-http://localhost:8080}"
HOST="${HOST%/}"          # strip trailing slash

# --- sample values for parametrised routes (override via env) ---
TAG="${TAG:-0001}"
BIBKEY="${BIBKEY:-sga4}"
CHAPTER="${CHAPTER:-1}"
TEX_FILE="${TEX_FILE:-preamble.tex}"
PDF_FILE="${PDF_FILE:-book.pdf}"

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
  "/tag/${TAG}/graph/topics"
  "/tag/${TAG}/graph/structure"
  "/tag/${TAG}/graph/tree"

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
FAIL=0
FAILED_ENDPOINTS=()

# Colour codes (disabled when not a terminal)
if [ -t 1 ]; then
  GREEN="\033[0;32m"; RED="\033[0;31m"; RESET="\033[0m"; BOLD="\033[1m"
else
  GREEN=""; RED=""; RESET=""; BOLD=""
fi

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
  else
    echo -e "  ${RED}FAIL${RESET} [${http_code}]  ${url}"
    FAILED_ENDPOINTS+=("${url}  (HTTP ${http_code})")
    (( FAIL++ )) || true
  fi
done

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
echo "-----------------------------------------------------------"
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  (total ${#ENDPOINTS[@]})"

if (( FAIL > 0 )); then
  echo -e "\n${BOLD}${RED}Failed endpoints:${RESET}"
  for entry in "${FAILED_ENDPOINTS[@]}"; do
    echo "  - ${entry}"
  done
  exit 1
fi

echo -e "${GREEN}All endpoints OK.${RESET}"
exit 0
