#!/bin/bash
#
# This script contains the storyboard for recording a terminal demo GIF.
# It uses 'vhs' (https://github.com/maaslalani/vhs) to generate the GIF.
#
# Prerequisites:
#   1. Install vhs: go install github.com/maaslalani/vhs@latest
#   2. A clean Ubuntu/Debian VM.
#   3. A GitHub repository with a simple Docker Compose project.
#   4. A GitHub Personal Access Token with 'repo' scope.
#
# Usage:
#   1. Replace placeholder values in this script.
#   2. Run 'vhs < scripts/record-demo.sh'
#   3. The output will be 'fastpull-demo.gif'.

# --- VHS Configuration ---
Output "fastpull-demo.gif"
Set FontSize 16
Set Width 1200
Set Height 800
Set TypingSpeed 100ms

# --- Demo Storyboard ---

# 1. Show the prompt and install fastpull
Type "curl -sSL https://raw.githubusercontent.com/YOUR_GITHUB_OWNER/YOUR_FASTPULL_REPO/main/scripts/curl-install.sh | bash"
Enter
Sleep 2s

# 2. Run setup
Type "sudo fastpull setup"
Enter
Sleep 1s

# Follow the prompts
# Scope: repo
Enter
Sleep 1s
# URL: Your repo URL
Type "https://github.com/YOUR_GITHUB_OWNER/YOUR_TEST_REPO"
Enter
Sleep 1s
# App Name
Enter
Sleep 1s
# Slug
Enter
Sleep 1s
# Labels
Enter
Sleep 1s
# Runner Base
Enter
Sleep 1s
# App Base
Enter
Sleep 1s
# Deploy Mode: docker
Enter
Sleep 1s
# Token: Paste your token here
Type "ghp_YourGitHubTokenGoesHere"
Enter
Sleep 5s

# 3. Show the list of runners
Type "sudo fastpull list"
Enter
Sleep 3s

# 4. Show the sample workflow file
Type "cat /opt/apps/your-test-repo/SAMPLE_deploy.yml"
Enter
Sleep 5s

# 5. Explain the next step (manual)
Hide
Show
Type "# Now, we copy this workflow into our repo, commit, and push..."
Sleep 3s
Type "git push"
Enter
Sleep 5s

# 6. Show the runner picking up the job (pretend)
Type "sudo fastpull status your-test-repo"
Enter
Sleep 5s
# Show logs indicating a job was run
# (This part is hard to automate in a recording, might need manual intervention or faked logs)

# End of recording
Sleep 2s
