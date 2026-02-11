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

# Get API token if provided (5th parameter)
api_token=""
if [ $# -ge 5 ] && [ -n "${5:-}" ]; then
    api_token="$5"
fi

# Determine authentication method
# Both API tokens and app passwords use HTTP Basic Authentication
# The only difference is the credential itself
if [ -n "$api_token" ]; then
    # Use API token with HTTP Basic Authentication
    echo "Using API token authentication..."
    auth_credential="$api_token"
elif [ -n "$password" ]; then
    # Use app password with HTTP Basic Authentication (deprecated)
    echo "Using app password authentication (deprecated, please migrate to API tokens)..."
    auth_credential="$password"
else
    echo "Error: Either 'api-token' or 'password' (deprecated) must be provided"
    exit 1
fi

CURL_OPTS=(-u "$username:$auth_credential" --silent)


echo "Validating BitBucket credentials..."
echo "Testing authentication for user: $username"
if ! curl_output=$(curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" 2>&1); then
    echo "ERROR: Authentication failed!"
    echo "Details: $curl_output"
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
        echo "Details: $create_output"
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
echo "Git URL format: https://$username:***@bitbucket.org/$spacename/$reponame.git"
if ! git_output=$(git push https://$username:$auth_credential@bitbucket.org/$spacename/$reponame.git --all --force 2>&1); then
    echo "ERROR: Git push failed!"
    echo "Details: $git_output"
    echo ""
    echo "Possible issues:"
    echo "  - API token may lack 'Repositories: Write' permission"
    echo "  - You may not have push access to this repository"
    echo "  - Repository name or workspace may be incorrect"
    exit 1
fi
echo "✓ Push successful"
