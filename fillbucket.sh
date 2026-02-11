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
if [ -n "$api_token" ]; then
    # Use API token with Bearer authentication
    echo "Using API token authentication..."
    CURL_OPTS=(--silent -H "Authorization: Bearer $api_token")
    GIT_USERNAME="x-token-auth"
    GIT_PASSWORD="$api_token"
elif [ -n "$password" ]; then
    # Use app password with basic authentication (deprecated)
    echo "Using app password authentication (deprecated, please migrate to API tokens)..."
    CURL_OPTS=(-u "$username:$password" --silent)
    GIT_USERNAME="$username"
    GIT_PASSWORD="$password"
else
    echo "Error: Either 'password' or 'api-token' must be provided"
    exit 1
fi


echo "Validating BitBucket credentials..."
curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" > /dev/null || (
    echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
    exit 1
)


reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if BitBucket repository \"$spacename/$reponame\" exists..."
curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" | grep "error" > /dev/null && (
    echo "BitBucket repository \"$spacename/$reponame\" does NOT exist, creating it..."
    curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' > /dev/null
)

echo "Pushing to remote..."
git push https://"$GIT_USERNAME:$GIT_PASSWORD"@bitbucket.org/$spacename/$reponame.git --all --force
