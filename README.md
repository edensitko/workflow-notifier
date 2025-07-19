# 🌐 Terraform Apply Notifier

Send **multi-channel notifications** (Discord, Slack, Telegram, Email) after a `terraform apply` or any other CI/CD event.

---

## 🚀 Features

- ✅ Built-in **template system** (`success`, `custom`) with variable placeholders.
- 📤 Sends messages to:
  - Discord
  - Slack
  - Telegram
  - Email (if `mail` command is available)
- 🔧 Easily trigger via GitHub Actions using [`repository_dispatch`](https://github.com/peter-evans/repository-dispatch).

---

## 📁 Folder Structure
terraform-apply-notifier/
├── notifier.sh              # Main script
├── templates/
│   ├── success.txt          # Default template
│   └── custom.txt           # Custom template (optional)

---

---

## 🛠️ Script Usage (Manual)

```bash
./notifier.sh \
  <status> \
  <message | "success" | "custom"> \
  <repo> \
  <env_name> \
  <actor> \
  <discord_webhook_url> \
  <slack_webhook_url> \
  <telegram_api_url> \
  <email_to>

  Example:
  ./notifier.sh \
    "success" \
    "success" \
    "your-repo" \
    "dev" \
    "your-actor" \
    "your-discord-webhook-url" \
    "your-slack-webhook-url" \
    "your-telegram-api-url" \
    "your-email-to"

  🧩 Templates (Optional)

Inside templates/ folder:

success.txt (default)
✅ Terraform apply completed successfully.
📦 Repo: $REPO
🌍 Environment: $ENV_NAME
👤 Actor: $ACTOR
🔧 Status: $STATUS
custom.txt (optional)
🔔 Custom Notification Triggered!
Repo: $REPO
Env: $ENV_NAME
User: $ACTOR
Status: $STATUS

---

## 📦 Environment Variables

- `ENV_NAME`: Environment name (e.g., `dev`, `prod`)
- `REPO`: Repository name
- `SLACK_WEBHOOK_URL`: Slack webhook URL
- `DISCORD_WEBHOOK_URL`: Discord webhook URL
- `TELEGRAM_API_URL`: Telegram API URL
- `EMAIL_TO`: Email recipient

---


## 📦 GitHub Actions Usage

```yaml
name: Terraform Apply Notification

on:
  repository_dispatch:
    types: [send-notification]

jobs:
  notify:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repo
        uses: actions/checkout@v4

      - name: Run Notifier Script
        run: |
          chmod +x ./notifier.sh
          ./notifier.sh \
            "${{ github.event.client_payload.status }}" \
            "${{ github.event.client_payload.message }}" \
            "${{ github.event.client_payload.repo }}" \
            "${{ github.event.client_payload.env_name }}" \
            "${{ github.event.client_payload.actor }}" \
            "${{ github.event.client_payload.discord_webhook_url }}" \
            "${{ github.event.client_payload.slack_webhook_url }}" \
            "${{ github.event.client_payload.telegram_api_url }}" \
            "${{ github.event.client_payload.email_to }}"
```

---

## 📦 Example Dispatch

```bash
gh repo dispatch create \
  --event-type send-notification \
  --json '{"status": "success", "message": "success", "repo": "your-repo", "env_name": "dev", "actor": "your-actor", "discord_webhook_url": "your-discord-webhook-url", "slack_webhook_url": "your-slack-webhook-url", "telegram_api_url": "your-telegram-api-url", "email_to": "your-email-to"}'
```

---

🧠 message can be:
	•	"success" → use templates/success.txt
	•	"custom" → use templates/custom.txt
	•	or a raw message like "Terraform failed ⚠️"

⸻

🛡️ How to Create and Use GH_PAT (Personal Access Token)
	1.	Go to: GitHub → Settings → Developer Settings → Tokens (Classic)
	2.	Click: Generate new token
	3.	Select scopes:
	•	repo
	•	workflow
	4.	Copy the token and save it in the repo that triggers the notification:
	•	Go to Settings > Secrets > Actions
	•	Add a secret called GH_PAT

⸻

🧪 Forking and Using as Your Own

If you don’t want to use the original terraform-apply-notifier, fork it:
	1.	Click Fork on this repo.
	2.	In your main repo, update the workflow:
repository: your-username/your-forked-repo
	3.	Push your own templates or modify the script.
	4.	Add your own GH_PAT with access to your fork.

---

🧩 Advanced: Use with Any CI/CD Tool

You can trigger notifier.sh manually from any CI tool (GitLab, Jenkins, etc.).

Just provide the inputs in correct order:

```bash
bash notifier.sh "success" "custom" "my-repo" "prod" "john" "..." "..." "..." "..."
```
👤 Author

Created by Eden Sitkovetsky
Feel free to contribute or open issues 🙌


