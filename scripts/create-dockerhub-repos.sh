#!/bin/bash
# create-dockerhub-repos.sh
# Helper script to create Docker Hub repositories via API

set -e

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-your-dockerhub-username}"
DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN:-your-access-token}"
ENVIRONMENT="${1:-dev}"

REPOS=(
  "frontend"
  "catalog-service"
  "cart-service"
  "order-service"
  "payment-service"
  "user-service"
  "notification-service"
  "admin-dashboard"
)

echo "Creating Docker Hub repositories for environment: $ENVIRONMENT"
echo "Username: $DOCKERHUB_USERNAME"
echo ""

for repo in "${REPOS[@]}"; do
  full_name="ecommerce-${ENVIRONMENT}-${repo}"
  echo -n "Creating $full_name... "

  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -u "$DOCKERHUB_USERNAME:$DOCKERHUB_TOKEN" \
    -d "{\"name\": \"$full_name\", \"namespace\": \"$DOCKERHUB_USERNAME\"}" \
    https://hub.docker.com/v2/repositories/)

  if [ "$response" = "201" ]; then
    echo "OK"
  elif [ "$response" = "400" ]; then
    echo "ALREADY EXISTS (or invalid name)"
  else
    echo "FAILED (HTTP $response)"
  fi
done

echo ""
echo "Done. Verify at: https://hub.docker.com/u/$DOCKERHUB_USERNAME"
