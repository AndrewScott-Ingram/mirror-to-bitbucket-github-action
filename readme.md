---
title: Mirror to Bitbucket GitHub Action
summary: GitHub Action to automatically mirror to Bitbucket.
---


Mirrors a GitHub Git repository to Bitbucket. If no corresponding Bitbucket repository exists, it is created using the [Bitbucket API 2.0](https://developer.atlassian.com/bitbucket/api/2/reference/).

**Please note**: make sure that you checkout the entire repository before using this. By default, `actions/checkout@v2` only creates a shallow clone. See section [example usage](#example-usage) on how to do a complete clone.

## Required Inputs

### `api-token` (Recommended)
Bitbucket API token for authentication and pushing. **As of September 9, 2025, app passwords can no longer be created, and existing app passwords will become inactive on June 9, 2026.**

**To create an API token:**
1. Go to your Bitbucket account settings
2. Navigate to Personal settings > API tokens
3. Create a new token with the following permissions:
	 - **Repositories**: Read, Write, Admin

Required token scopes:
- `read:user:bitbucket`
- `read:repository:bitbucket`
- `write:repository:bitbucket`
- `admin:repository:bitbucket`

API tokens use HTTP Basic Authentication with your Bitbucket username and the token as the password.

**API tokens require your Atlassian account email for authentication.** Provide it via the `email` input (recommended) or set `username` to your email.

For more information, see [Bitbucket's API token documentation](https://support.atlassian.com/bitbucket-cloud/docs/using-api-tokens/).

### `password` (Deprecated)
App password for authentication (deprecated). **Use `api-token` instead.** This parameter is maintained for backward compatibility but will be removed in a future version.

If you still need to use an app password, create a new [App Password](https://bitbucket.org/account/settings/app-passwords/) with the following permissions:


## Optional Inputs
### `username`
Username to use on Bitbucket for 1) authentication and as 2) workspace name. Default: GitHub user name.

### `email`
Atlassian account email used for API token authentication. Required when using `api-token` unless `username` is already set to an email address.

**When using `api-token`, set `username` to your Atlassian account email.** Bitbucket API tokens require the email for authentication (see Atlassian docs linked above).

### `repository`
Name of the repository on Bitbucket. If it does not exist, it is created automatically. Default: GitHub repository name.

### `spacename`
Name of the space in which the repository should be contained on Bitbucket. Default:  GitHub user name.

## Outputs
None


## Example usage

			- name: Checkout
				uses: actions/checkout@v4
				with:
					fetch-depth: 0 # <-- clone with complete history
			- name: Push
				uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
				with:
					email: ${{ secrets.BITBUCKET_EMAIL }}
					api-token: ${{ secrets.BITBUCKET_API_TOKEN }}

## Example with all parameters

			- name: Checkout
				uses: actions/checkout@v4
				with:
					fetch-depth: 0 # <-- clone with complete history
			- name: Push
				uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
				with:
					username: mybitbucketusername
					email: my.name@example.com
					spacename: teamspace
					repository: bestrepo
					api-token: ${{ secrets.BITBUCKET_API_TOKEN }}

## Local usage (fillbucket.sh)

If you run the script directly, use this parameter order:

```
./fillbucket.sh <username> <password-or-api-token> <repository> <spacename> [email-or-api-token] [email]
```

Notes:
- If you pass an API token as the 2nd parameter, pass the Atlassian account email as the 5th parameter.
- If you pass an API token as the 5th parameter, pass the email as the 6th parameter.
- App passwords are deprecated; prefer API tokens.

## Migration from v2 to v4

If you're upgrading from v2, you need to:

1. Create a Bitbucket API token (see instructions above)
2. Store the token as a GitHub secret (e.g., `BITBUCKET_API_TOKEN`)
3. Ensure your workflow uses the new `email` input (or set `username` to your email):

```yaml
# Before (v2)
- uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v2
	with:
		password: ${{ secrets.BITBUCKET_PASSWORD }}

# After (v4)
- uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
	with:
		email: ${{ secrets.BITBUCKET_EMAIL }}
		api-token: ${{ secrets.BITBUCKET_API_TOKEN }}
```

Note: v3 still supports the `password` parameter for backward compatibility, but it will be removed in a future version.