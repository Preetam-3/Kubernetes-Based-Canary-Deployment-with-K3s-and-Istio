#!/usr/bin/env bash
# Usage: bash scripts/traffic-test.sh [requests] [url]
# Sends N requests through the Istio ingress gateway and counts how many
# times each distinct response comes back (v1 vs v2), with percentages.

N="${1:-100}"
URL="${2:-http://localhost/}"

echo "Sending $N requests to $URL ..."
echo

RESULTS=$(for _ in $(seq 1 "$N"); do
  curl -s --max-time 5 "$URL" | tr -d '\r' | head -c 200 | tr '\n' ' '
  echo
done)

FAILED=$(echo "$RESULTS" | grep -c '^[[:space:]]*$')

echo "$RESULTS" | grep -v '^[[:space:]]*$' | sort | uniq -c | sort -rn | \
while read -r count body; do
  pct=$(( count * 100 / N ))
  printf '%4d requests (%3d%%)  %s\n' "$count" "$pct" "$body"
done

if [ "$FAILED" -gt 0 ]; then
  echo
  echo "WARNING: $FAILED request(s) failed or returned nothing."
fi
