---
title: Mirror to Bitbucket GitHub Action
summary: GitHub Action zum automatischen Spiegeln nach Bitbucket.
---


Spiegelt ein GitHub-Git-Repository nach Bitbucket. Falls kein entsprechendes Bitbucket-Repository existiert, wird es automatisch über die [Bitbucket API 2.0](https://developer.atlassian.com/bitbucket/api/2/reference/) erstellt.

**Bitte beachten**: Stelle sicher, dass du das komplette Repository auscheckst. Standardmäßig erstellt `actions/checkout@v2` nur einen flachen Klon. Siehe Abschnitt [Beispielnutzung](#beispielnutzung) für ein vollständiges Checkout.

## Erforderliche Inputs

### `api-token` (Empfohlen)
Bitbucket API-Token für Authentifizierung und Push. **Seit dem 9. September 2025 können keine App-Passwörter mehr erstellt werden, und bestehende App-Passwörter werden am 9. Juni 2026 deaktiviert.**

**API-Token erstellen:**
1. Gehe zu den Bitbucket-Kontoeinstellungen
2. Navigiere zu Personal settings > API tokens
3. Erstelle ein neues Token mit den folgenden Berechtigungen:
	 - **Repositories**: Read, Write, Admin

Erforderliche Token-Scopes:
- `read:user:bitbucket`
- `read:repository:bitbucket`
- `write:repository:bitbucket`
- `admin:repository:bitbucket`

API-Token verwenden HTTP Basic Authentication mit deinem Bitbucket-Benutzernamen und dem Token als Passwort.

**API-Token benötigen die Atlassian-Konto-E-Mail für die Authentifizierung.** Gib sie über den Input `email` an (empfohlen) oder setze `username` auf deine E-Mail-Adresse.

Weitere Informationen: [Bitbucket API Token Dokumentation](https://support.atlassian.com/bitbucket-cloud/docs/using-api-tokens/).

### `password` (Veraltet)
App-Passwort für die Authentifizierung (veraltet). **Verwende stattdessen `api-token`.** Dieser Parameter bleibt aus Kompatibilitätsgründen vorerst erhalten, wird aber in einer zukünftigen Version entfernt.

Wenn du weiterhin ein App-Passwort verwenden musst, erstelle ein neues [App Password](https://bitbucket.org/account/settings/app-passwords/) mit den folgenden Berechtigungen:


## Optionale Inputs
### `username`
Benutzername für Bitbucket für 1) Authentifizierung und 2) Workspace-Name. Standard: GitHub-Benutzername.

### `email`
Atlassian-Konto-E-Mail für die API-Token-Authentifizierung. Erforderlich bei `api-token`, sofern `username` nicht bereits eine E-Mail-Adresse ist.

**Bei `api-token` setze `username` auf deine Atlassian-Konto-E-Mail.** Bitbucket API-Token benötigen die E-Mail für die Authentifizierung (siehe Atlassian-Doku oben).

### `repository`
Name des Repositories auf Bitbucket. Wenn es nicht existiert, wird es automatisch erstellt. Standard: GitHub-Repositoryname.

### `spacename`
Name des Workspace, in dem das Repository liegen soll. Standard: GitHub-Benutzername.

## Outputs
Keine


## Beispielnutzung

			- name: Checkout
				uses: actions/checkout@v4
				with:
					fetch-depth: 0 # <-- vollständige Historie klonen
			- name: Push
				uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
				with:
					email: ${{ secrets.BITBUCKET_EMAIL }}
					api-token: ${{ secrets.BITBUCKET_API_TOKEN }}

## Beispiel mit allen Parametern

			- name: Checkout
				uses: actions/checkout@v4
				with:
					fetch-depth: 0 # <-- vollständige Historie klonen
			- name: Push
				uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
				with:
					username: mybitbucketusername
					email: my.name@example.com
					spacename: teamspace
					repository: bestrepo
					api-token: ${{ secrets.BITBUCKET_API_TOKEN }}

## Lokale Nutzung (fillbucket.sh)

Wenn du das Script direkt ausführst, nutze diese Parameterreihenfolge:

```
./fillbucket.sh <username> <password-or-api-token> <repository> <spacename> [email-or-api-token] [email]
```

Hinweise:
- Wenn du ein API-Token als 2. Parameter übergibst, gib die Atlassian-Konto-E-Mail als 5. Parameter an.
- Wenn du ein API-Token als 5. Parameter übergibst, gib die E-Mail als 6. Parameter an.
- App-Passwörter sind veraltet; verwende API-Token.

## Migration von v2 zu v4

Wenn du von v2 upgraden möchtest, musst du:

1. Ein Bitbucket API-Token erstellen (siehe oben)
2. Das Token als GitHub-Secret speichern (z. B. `BITBUCKET_API_TOKEN`)
3. Sicherstellen, dass dein Workflow den neuen Input `email` nutzt (oder `username` auf deine E-Mail setzen):

```yaml
# Vorher (v2)
- uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v2
	with:
		password: ${{ secrets.BITBUCKET_PASSWORD }}

# Nachher (v4)
- uses: AndrewScott-Ingram/mirror-to-bitbucket-github-action@v4
	with:
		email: ${{ secrets.BITBUCKET_EMAIL }}
		api-token: ${{ secrets.BITBUCKET_API_TOKEN }}
```

Hinweis: v3 unterstützt den Parameter `password` aus Kompatibilitätsgründen weiterhin, wird ihn jedoch in einer zukünftigen Version entfernen.