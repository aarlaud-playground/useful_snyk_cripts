#!/bin/bash

if command -v jq &> /dev/null; then
  echo "jq - OK"
else
  echo "jq is not installed. Please install it."
  echo "You can install it using your package manager."
  echo "Exiting."
  exit 2
fi

if command -v curl &> /dev/null; then
  echo "curl - OK"
else
  echo "curl is not installed. Please install it."
  echo "You can install it using your package manager."
  echo "Exiting."
  exit 2
fi

if command -v sed &> /dev/null; then
  echo "sed - OK"
else
  echo "sed is not installed. Please install it."
  echo "You can install it using your package manager."
  echo "Exiting."
  exit 2
fi

if command -v tr &> /dev/null; then
  echo "tr - OK"
else
  echo "tr is not installed. Please install it."
  echo "You can install it using your package manager."
  echo "Exiting."
  exit 2
fi

if [ $# -eq 5 ]; then
  echo ""
  # Process the arguments: $1, $2, and $3
else
  echo "Error: Please provide exactly 5 arguments: Snyk Token, Org Id, Target Name, User Id, retest frequency."
  # Exit script with an error code (optional)
  exit 1
fi

case "$5" in
  "never" | "daily" | "weekly")
    echo "Desired frequency: $5"
    ;;
  *)
    echo "Error: Invalid argument. Please use 'never', 'daily', or 'weekly'."
    exit 1  # Exit script with error code
    ;;
esac

echo ""
echo ""
SNYK_TOKEN=$1
SNYK_ORG_ID=$2
SNYK_TARGET_NAME=$(echo "$3" | sed 's/\//%2F/g')
SNYK_USER_ID=$4
FREQUENCY=$5

echo ""
echo "Step 1/3: Finding target ID for $SNYK_TARGET_NAME"
TARGET_ID=$(curl -s -H "Authorization: token ${SNYK_TOKEN}" -H 'Content-type: application/vnd.api+json' https://api.snyk.io/rest/orgs/${SNYK_ORG_ID}/targets\?version\=2024-06-06\&display_name\=${SNYK_TARGET_NAME} | jq '.data | .[0].id')

TARGET_ID=$(echo "$TARGET_ID" | tr -d '"')

if [ "$TARGET_ID" = "null" ]; then
    echo "  => Could not find target $SNYK_TARGET_NAME. exiting"
    exit 1
else
    echo "  => Found target ID: $TARGET_ID"
fi


echo ""
echo "Step 2/3: Finding projects for target ID $TARGET_ID"
PAGE=$(curl -s -H "Authorization: token ${SNYK_TOKEN}" -H 'Content-type: application/vnd.api+json' https://api.snyk.io/rest/orgs/${SNYK_ORG_ID}/projects\?version\=2024-06-06\&target_id\=${TARGET_ID})
PROJECT_IDS=$(echo $PAGE | jq '.data | .[].id')
NEXT_PAGE=$(echo $PAGE | jq '.links.next')

while [ -n "$NEXT_PAGE" ];
do
NEXT_PAGE=$(echo $NEXT_PAGE | tr -d '"')
PAGE=$(curl -s -H "Authorization: token ${SNYK_TOKEN}" -H 'Content-type: application/vnd.api+json' https://api.snyk.io${NEXT_PAGE})
if [ -n "$PAGE" ]; then
  PROJECT_IDS+="
  $(echo $PAGE | jq '.data | .[].id')"
fi
NEXT_PAGE=$(echo $PAGE | jq '.links.next')
done

echo "  => Found projects:"
while read -r project; do
    echo "      - $project" | tr -d '"'
done <<< "$PROJECT_IDS"

echo "Step 3/3: Setting retest frequency to $FREQUENCY"
while read -r project; do
    PROJECTID=$(echo $project | tr -d '"')
    curl -s -o /dev/null -X PATCH -H "Authorization: token ${SNYK_TOKEN}" -H 'Content-type: application/vnd.api+json' https://api.snyk.io/rest/orgs/${SNYK_ORG_ID}/projects/${PROJECTID}\?version\=2024-06-06 -d "{ \"data\": {\"attributes\": {\"test_frequency\": \"$FREQUENCY\"},\"id\": \"${PROJECTID}\",\"relationships\": { \"owner\": {\"data\": { \"id\": \"${SNYK_USER_ID}\", \"type\": \"user\"   }    }  },\"type\": \"project\"}}"
    echo "      - $PROJECTID - DONE"
done <<< "$PROJECT_IDS"

echo "Completed."
