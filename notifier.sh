#!/bin/bash

# Terraform Apply Notifier
# Sends notifications to Discord, Slack, and Telegram webhooks using templates

# Enable debugging
set -x

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get arguments with defaults
STATUS="${1:-Success}"
MESSAGE_TYPE="${2:-default}"
REPO="${3:-Unknown}"
ENV_NAME="${4:-dev}"
ACTOR="${5:-System}"
DISCORD_WEBHOOK_URL="$6"
SLACK_WEBHOOK_URL="$7"
TELEGRAM_API_URL="$8"

# Define fallback messages for each type
FALLBACK_SUCCESS_PLAN="✅ Terraform Plan Success "
FALLBACK_SUCCESS_APPLY="✅ Terraform Apply Success"
FALLBACK_SUCCESS_DESTROY="🗑️ Terraform Destroy success"
FALLBACK_DEFAULT="⚠️ Terraform Notification"

# Determine template path based on message type
echo "==== TEMPLATE SELECTION ====" 
case "$MESSAGE_TYPE" in
  "success-plan")
    TEMPLATE_PATH="$SCRIPT_DIR/templates/success-plan.txt"
    FALLBACK_MESSAGE="$FALLBACK_SUCCESS_PLAN"
    ;;
  "success-apply")
    TEMPLATE_PATH="$SCRIPT_DIR/templates/success-apply.txt"
    FALLBACK_MESSAGE="$FALLBACK_SUCCESS_APPLY"
    ;;
  "success-destroy")
    TEMPLATE_PATH="$SCRIPT_DIR/templates/success-destroy.txt"
    FALLBACK_MESSAGE="$FALLBACK_SUCCESS_DESTROY"
    ;;
  "custom")
    TEMPLATE_PATH="$SCRIPT_DIR/templates/custom.txt"
    FALLBACK_MESSAGE="$FALLBACK_DEFAULT"
    ;;
  *)
    TEMPLATE_PATH="$SCRIPT_DIR/templates/success-apply.txt"
    FALLBACK_MESSAGE="$FALLBACK_DEFAULT"
    ;;
esac

echo "Looking for template: $TEMPLATE_PATH"
ls -la "$SCRIPT_DIR/templates/" || echo "No templates directory found"

# Try to load template content with robust error handling
if [ -f "$TEMPLATE_PATH" ]; then
  echo "Template found at $TEMPLATE_PATH"
  
  # Read template content safely line by line
  TEMPLATE_CONTENT=""
  while IFS= read -r line || [ -n "$line" ]; do
    TEMPLATE_CONTENT="${TEMPLATE_CONTENT}${line}\n"
  done < "$TEMPLATE_PATH"
  
  echo "Raw template content length: ${#TEMPLATE_CONTENT}"
  
  # Only use template if it's not empty
  if [ -n "$TEMPLATE_CONTENT" ]; then
    echo "Using template content"
    
    # Replace variables in template
    MESSAGE="$TEMPLATE_CONTENT"
    MESSAGE="${MESSAGE//\$\{STATUS\}/$STATUS}"
    MESSAGE="${MESSAGE//\$\{REPO\}/$REPO}"
    MESSAGE="${MESSAGE//\$\{ENV_NAME\}/$ENV_NAME}"
    MESSAGE="${MESSAGE//\$\{ACTOR\}/$ACTOR}"
    
    # Also support variables without braces
    MESSAGE="${MESSAGE//\$STATUS/$STATUS}"
    MESSAGE="${MESSAGE//\$REPO/$REPO}"
    MESSAGE="${MESSAGE//\$ENV_NAME/$ENV_NAME}"
    MESSAGE="${MESSAGE//\$ACTOR/$ACTOR}"
  else
    echo "Template file exists but is empty, using fallback message"
    MESSAGE="$FALLBACK_MESSAGE"
  fi
else
  echo "Template not found at $TEMPLATE_PATH, using fallback message"
  MESSAGE="$FALLBACK_MESSAGE"
fi

# Final safety check - if message is somehow still empty, use fallback message
if [ -z "$MESSAGE" ]; then
  echo "WARNING: Message is still empty after all processing, using fallback message"
  MESSAGE="$FALLBACK_MESSAGE"
fi

echo "==== FINAL MESSAGE ===="
echo "$MESSAGE"

# Send to Discord
if [ ! -z "$DISCORD_WEBHOOK_URL" ]; then
  echo "==== SENDING TO DISCORD ===="
  
  # Properly escape the message for JSON
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  # Create JSON payload with proper escaping
  PAYLOAD='{"content":"'"$ESCAPED_MESSAGE"'"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  # Send to Discord with detailed output
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$DISCORD_WEBHOOK_URL"
  
  echo "Discord notification attempt complete"
fi

# Send to Slack
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
  echo "==== SENDING TO SLACK ===="
  
  # Properly escape the message for JSON
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  # Create JSON payload with proper escaping
  PAYLOAD='{"text":"'"$ESCAPED_MESSAGE"'"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  # Send to Slack with detailed output
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$SLACK_WEBHOOK_URL"
  
  echo "Slack notification attempt complete"
fi

# Send to Telegram
if [ ! -z "$TELEGRAM_API_URL" ]; then
  echo "==== SENDING TO TELEGRAM ===="
  
  # Properly escape the message for JSON
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  # Create JSON payload with proper escaping
  PAYLOAD='{"text":"'"$ESCAPED_MESSAGE"'", "parse_mode":"Markdown"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  # Send to Telegram with detailed output
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$TELEGRAM_API_URL"
  
  echo "Telegram notification attempt complete"
fi

echo "==== NOTIFICATION PROCESS COMPLETE ===="
