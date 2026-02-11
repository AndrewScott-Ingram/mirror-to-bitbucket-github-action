#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

trap "echo 'Missing parameter'; exit 1" INT TERM EXIT
username="$1"
password="$2"
reponame="$3"
trap - INT TERM EXIT

spacename="$username"
if [ $# -ge 4 ]; then
    spacename="$4"
fi

# Get API token or email if provided after spacename.
# Param 5 can be either an API token or an email (when token is in param 2).
api_token=""
login_user="$username"
git_login_user="$username"
if [ $# -ge 5 ] && [ -n "${5:-}" ]; then
    if [[ "${5:-}" == *"@"* ]]; then
        login_user="$5"
    else
        api_token="$5"
    fi
fi
# Param 6 can be the email when param 5 is the token.
if [ $# -ge 6 ] && [ -n "${6:-}" ]; then
    login_user="$6"
fi
# If username already looks like an email, use it.
if [[ "$username" == *"@"* ]]; then
    login_user="$username"
    git_login_user="$username"
fi

# Determine authentication method
# Both API tokens and app passwords use HTTP Basic Authentication
# The only difference is the credential itself
# Check if password starts with "ATATT" or "ATCTT" (Bitbucket API token pattern)
if [ -n "$api_token" ]; then
    # Use API token with HTTP Basic Authentication (from 5th parameter)
    echo "Using API token authentication..."
    auth_credential="$api_token"
elif [[ "$password" == ATATT* ]] || [[ "$password" == ATCTT* ]]; then
    # Password looks like an API token (from 2nd parameter)
    echo "Using API token authentication..."
    auth_credential="$password"
elif [ -n "$password" ]; then
    # Use app password with HTTP Basic Authentication (deprecated)
    echo "Using app password authentication (deprecated, please migrate to API tokens)..."
    auth_credential="$password"
else
    echo "Error: Either 'api-token' or 'password' (deprecated) must be provided"
    exit 1
fi

if { [ -n "$api_token" ] || [[ "$password" == ATATT* ]] || [[ "$password" == ATCTT* ]]; } && [[ "$login_user" != *"@"* ]]; then
    echo "WARNING: API tokens require Atlassian account email for authentication."
    echo "         Pass email as 6th parameter or use email as the username."
fi

CURL_OPTS=(-u "$login_user:$auth_credential" --silent)


echo "Validating BitBucket credentials..."
echo "Testing authentication for user: $login_user"
if ! curl_output=$(curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" 2>&1); then
    echo "ERROR: Authentication failed!"
    # Filter out credentials from error output
    filtered_output=$(echo "$curl_output" | sed "s/$auth_credential/***/g")
    echo "Details: $filtered_output"
    echo ""
    echo "Possible issues:"
    echo "  - Invalid username or API token/password"
    echo "  - API token may not have required permissions"
    echo "  - Network connectivity issues"
    exit 1
fi
echo "✓ Authentication successful"


reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if BitBucket repository \"$spacename/$reponame\" exists..."
repo_check_output=$(curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" 2>&1)
if echo "$repo_check_output" | grep -q "error"; then
    echo "BitBucket repository \"$spacename/$reponame\" does NOT exist, creating it..."
    if ! create_output=$(curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' 2>&1); then
        echo "ERROR: Failed to create repository!"
        # Filter out credentials from error output
        filtered_output=$(echo "$create_output" | sed "s/$auth_credential/***/g")
        echo "Details: $filtered_output"
        echo ""
        echo "Possible issues:"
        echo "  - API token may lack 'Repositories: Admin' permission"
        echo "  - Workspace/spacename may not exist or you may not have access"
        exit 1
    fi
    echo "✓ Repository created successfully"
else
    echo "✓ Repository exists"
fi

echo "Pushing to remote..."
remote_url="https://bitbucket.org/$spacename/$reponame.git"
echo "Git URL format: https://***@bitbucket.org/$spacename/$reponame.git"
# Use Authorization header to avoid issues with @ in email username.
auth_header=$(printf '%s' "$git_login_user:$auth_credential" | base64 | tr -d '\r\n')
echo "Git auth user: $git_login_user"
if ! git_output=$(git -c http.extraHeader="Authorization: Basic $auth_header" push "$remote_url" --all --force 2>&1); then
    echo "ERROR: Git push failed!"
    # Filter out credentials from error output
    filtered_output=$(echo "$git_output" | sed "s/$auth_credential/***/g")
    echo "Details: $filtered_output"
    echo ""
    echo "Possible issues:"
    echo "  - API token may lack 'Repositories: Write' permission"
    echo "  - You may not have push access to this repository"
    echo "  - Repository name or workspace may be incorrect"
    exit 1
fi
echo "✓ Push successful"
