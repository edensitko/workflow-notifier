#!/bin/bash

# Sends notifications to Discord, Slack, and Telegram webhooks using templates 
# you can add more webhooks by adding more arguments to the script

set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATUS="${1:-Success}"
MESSAGE_TYPE="${2:-default}"
REPO="${3:-Unknown}"
ENV_NAME="${4:-dev}"
ACTOR="${5:-System}"
DISCORD_WEBHOOK_URL="$6"
SLACK_WEBHOOK_URL="$7"
TELEGRAM_API_URL="$8"
TIME="${9:-$(date '+%Y-%m-%d %H:%M:%S')}"

# fallback messages 
FALLBACK_SUCCESS_PLAN="✅ Terraform Plan Success "
FALLBACK_SUCCESS_APPLY="✅ Terraform Apply Success"
FALLBACK_SUCCESS_DESTROY="🗑️ Terraform Destroy success"
FALLBACK_DEFAULT="⚠️ Terraform Notification"

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

if [ -f "$TEMPLATE_PATH" ]; then
  echo "Template found at $TEMPLATE_PATH"
  
  TEMPLATE_CONTENT=""
  while IFS= read -r line || [ -n "$line" ]; do
    TEMPLATE_CONTENT="${TEMPLATE_CONTENT}${line}\n"
  done < "$TEMPLATE_PATH"
  
  echo "Raw template content length: ${#TEMPLATE_CONTENT}"
  
  if [ -n "$TEMPLATE_CONTENT" ]; then
    echo "Using template content"
    
    MESSAGE="$TEMPLATE_CONTENT"
    MESSAGE="${MESSAGE//\$\{STATUS\}/$STATUS}"
    MESSAGE="${MESSAGE//\$\{REPO\}/$REPO}"
    MESSAGE="${MESSAGE//\$\{ENV_NAME\}/$ENV_NAME}"
    MESSAGE="${MESSAGE//\$\{ACTOR\}/$ACTOR}"
    MESSAGE="${MESSAGE//\$\{TIME\}/$TIME}"
  else
    echo "Template file exists but is empty, using fallback message"
    MESSAGE="$FALLBACK_MESSAGE"
  fi
else
  echo "Template not found at $TEMPLATE_PATH, using fallback message"
  MESSAGE="$FALLBACK_MESSAGE"
fi

if [ -z "$MESSAGE" ]; then
  echo "WARNING: Message is still empty after all processing, using fallback message"
  MESSAGE="$FALLBACK_MESSAGE"
fi

echo "==== FINAL MESSAGE ===="
echo "$MESSAGE"

# ==== DISCORD NOTIFICATION ====

if [ ! -z "$DISCORD_WEBHOOK_URL" ]; then
  echo "==== SENDING TO DISCORD ===="
  
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  PAYLOAD='{"content":"'"$ESCAPED_MESSAGE"'"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$DISCORD_WEBHOOK_URL"
  
  echo "Discord notification attempt complete"
fi

# ==== SLACK NOTIFICATION ====

if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
  echo "==== SENDING TO SLACK ===="
  
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  PAYLOAD='{"text":"'"$ESCAPED_MESSAGE"'"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$SLACK_WEBHOOK_URL"
  
  echo "Slack notification attempt complete"
fi

# ==== TELEGRAM NOTIFICATION ====
 
if [ ! -z "$TELEGRAM_API_URL" ]; then
  echo "==== SENDING TO TELEGRAM ===="
  
  ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
  
  PAYLOAD='{"text":"'"$ESCAPED_MESSAGE"'", "parse_mode":"Markdown"}'
  echo "Sending payload of length: ${#PAYLOAD}"
  
  curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$TELEGRAM_API_URL"
  
  echo "Telegram notification attempt complete"
fi

echo "==== NOTIFICATION PROCESS COMPLETE ===="
