# 🌐 workflow notifier 
 Notification system that sends **multi-channel alerts** to Discord, Slack, and Telegram after Terraform operations or any CI/CD event. Perfect for keeping your team informed about infrastructure changes in real-time.

*the repo is ready for terraform workflow usage*

---

## 🚀 Features

- ✅ **Template-based notifications** with multiple pre-defined templates for different scenarios
- 📤 **Multi-channel support** - send notifications to:
  - Discord
  - Slack
  - Telegram
  - you can add more channels by adding more arguments to the script
- 🔄 **GitHub Actions integration** via repository_dispatch events
- 🛡️ **Robust error handling** with fallback messages if templates fail
- 🧩 **Variable substitution** in templates (repo, environment, actor, status, time)

---

## 📁 Project Structure

```
terraform-apply-notifier/
├── notifier.sh                   
├── .github/
│   └── workflows/
│       └── on-dispatch.yml       
└── templates/
    ├── success-plan.txt           
    ├── success-apply.txt          
    ├── success-destroy.txt        
    └── custom.txt                 
```

---

## 🛠️ How to Use

### Manual Script Usage

```bash
./notifier.sh \
  <status> \
  <message_type> \
  <repo> \
  <env_name> \
  <actor> \
  <discord_webhook_url> \
  <slack_webhook_url> \
  <telegram_api_url> \
  <time>
```

#### Parameters:

| Parameter | Description | Example |
|-----------|-------------|--------|
| `status` | Status of the operation | `"Success"`, `"Failed"` |
| `message_type` | Template to use | `"success-plan"`, `"success-apply"`, `"success-destroy"`, `"custom"` |
| `repo` | Repository name | `"terraform-aws-modules"` |
| `env_name` | Environment name | `"production"`, `"staging"` |
| `actor` | User who triggered the action | `"username"` |
| `discord_webhook_url` | Discord webhook URL | `"https://discord.com/api/webhooks/..."` |
| `slack_webhook_url` | Slack webhook URL | `"https://hooks.slack.com/services/..."` |
| `telegram_api_url` | Telegram API URL | `"https://api.telegram.org/bot..."` |
| `time` | Timestamp (optional) | `"2025-07-19 12:00:00"` |

### 🧩 Template System

The repository includes several template files in the `templates/` directory. Here's an example of what a template looks like:

```
✅ Terraform operation completed successfully!

📦 Repo: $REPO
🌍 Environment: $ENV_NAME
👤 By: $ACTOR
🔧 Status: $STATUS
⏰ $TIME
```

Available templates:
- `success-plan.txt` - Used for successful Terraform plan operations
- `success-apply.txt` - Used for successful Terraform apply operations
- `success-destroy.txt` - Used for successful Terraform destroy operations
- `custom.txt` - Template for custom notifications

---

## 🔑 Required Secrets for GitHub Actions

When using this with GitHub Actions, you'll need to set up the following secrets in your repository:

- `GH_PAT`: GitHub Personal Access Token with `repo` and `workflow` permissions
- `DISCORD_WEBHOOK_URL`: Your Discord webhook URL
- `SLACK_WEBHOOK_URL`: Your Slack webhook URL
- `TELEGRAM_API_URL`: Your Telegram API URL

---

## 🛡️ Setting Up GitHub Personal Access Token (GH_PAT)

1. Go to: GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (Classic)
2. Click: Generate new token
3. Name it something descriptive like "Terraform Notification Token"
4. Select these scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. Click "Generate token" and copy it immediately
6. In the repository that will trigger notifications:
   - Go to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `GH_PAT`
   - Value: Paste your token
   - Click "Add secret"

---

## 🔄 GitHub Actions workflow Integration

This repository includes a GitHub Actions workflow file at `.github/workflows/on-dispatch.yml` that handles incoming notification requests. The workflow:

1. Is triggered by `repository_dispatch` events of type `send-notification`
2. Checks out the repository code
3. Runs the notifier script with parameters from the event payload

Key parameters passed from the event payload include:
- Status of the operation
- Message type (which template to use)
- Repository name
- Environment name
- Actor name
- Webhook URLs
- Timestamp
```

---

### how to use the repo in your terraform workflow

fork the repo and use it in your terraform workflow
add the following code to your terraform workflow

```yaml
- name: Get current time
  id: current-time
  run: echo "time=$(date '+%Y-%m-%d %H:%M:%S')" >> $GITHUB_OUTPUT

- name: 🔁 Trigger Notification
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.GH_PAT }}
    repository: ${{ github.repository }}
    event-type: send-notification
    client-payload: |
      {
        "status": "success",
        "message": "success-plan",
        "repo": "${{ github.repository }}",
        "env_name": "${{ env.ENV_NAME }}",
        "actor": "${{ github.actor }}",
        "discord_webhook_url": "${{ secrets.DISCORD_WEBHOOK_URL }}",
        "slack_webhook_url": "${{ secrets.SLACK_WEBHOOK_URL }}",
        "telegram_api_url": "${{ secrets.TELEGRAM_API_URL }}",
        "time": "${{ steps.current-time.outputs.time }}"
      }
```

---

## 🧪 Customizing Templates

### Creating Custom Template Files

To create and use a new custom template:

1. Create a new text file in the `templates/` directory (e.g., `templates/my-custom-template.txt`)
2. Add your notification content using available variables:
   ```
   🚨 Custom Alert: $STATUS
   📦 Project: $REPO
   🌍 Environment: $ENV_NAME
   👤 By: $ACTOR
   ⏰ $TIME
   ```

3. When triggering a notification, set the `message` parameter to your template name without the `.txt` extension:
   ```bash
   # Using custom template
   ./notifier.sh "Success" "my-custom-template" ...
   ```
   
   Or in GitHub Actions:
   ```yaml
   client-payload: |
     {
       "message": "my-custom-template",
       ...
     }
   ```

The script will automatically look for `templates/my-custom-template.txt` based on the message parameter.

## 🔌 Integration with Other CI/CD Tools

You can use this notification system with any CI/CD tool that can make HTTP requests:

### Other CI/CD Tools

You can integrate with other CI/CD tools by making HTTP requests to trigger the GitHub repository dispatch event. For example:

```bash
# Generic example for any CI system
curl -X POST https://api.github.com/repos/edensitko/terraform-apply-notifier/dispatches \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GH_PAT" \
  -d '{"event_type":"send-notification","client_payload":{"status":"success","message":"success-apply","repo":"my-repo","env_name":"production","actor":"ci-user","discord_webhook_url":"...","slack_webhook_url":"...","telegram_api_url":"...","time":"'$(date '+%Y-%m-%d %H:%M:%S')'"}}'  
```

This works with GitLab CI, Jenkins, CircleCI, or any system that can execute shell commands.

---

## 👤 Author

Created by Eden Sitkovetsky

Feel free to contribute or open issues 🙌


# workflow-notifier
