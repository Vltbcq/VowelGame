#!/usr/bin/env bash
# Description courte d'une Release : 4-5 lignes max + lien vers le changelog détaillé.
# Usage : release_body.sh <version>   (écrit sur la sortie standard)
# - Résumé écrit à la main : .github/release-notes/<version>.md (utilisé tel quel s'il existe)
# - Sinon : les 4 derniers titres de commits, puis « … et N autres changements »
set -euo pipefail
VERSION="$1"
REPO="${GITHUB_REPOSITORY:-Vltbcq/VowelGame}"
TO="HEAD"
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then TO="$VERSION"; fi
# Version précédente = le tag juste avant celui-ci (ou le plus récent si ce tag n'existe pas encore)
TAGS=$(git tag --list 'v*' --sort=-creatordate)
if echo "$TAGS" | grep -qx "$VERSION"; then
  PREV=$(echo "$TAGS" | sed -n "/^${VERSION//./\\.}\$/{n;p;q}")
else
  PREV=$(echo "$TAGS" | head -n1)
fi
RANGE="$TO"
if [ -n "$PREV" ]; then RANGE="$PREV..$TO"; fi

echo "## Nouveautés"
NOTES=".github/release-notes/$VERSION.md"
if [ -f "$NOTES" ]; then
  sed '/^[[:space:]]*$/d' "$NOTES" | head -n 5
else
  TOTAL=$(git rev-list --no-merges --count "$RANGE")
  git log --no-merges --format='- %s' "$RANGE" | head -n 4
  if [ "$TOTAL" -gt 4 ]; then echo "- … et $((TOTAL - 4)) autres changements"; fi
fi
echo
if [ -n "$PREV" ]; then
  echo "📜 [Changelog détaillé ($PREV → $VERSION)](https://github.com/$REPO/compare/$PREV...$VERSION)"
else
  echo "📜 [Changelog détaillé](https://github.com/$REPO/commits/$VERSION)"
fi
echo
echo "▶ Télécharge \`Vowel.exe\` (ou \`Vowel-windows.zip\`, plus léger). Si Windows bloque : *Informations complémentaires* → *Exécuter quand même*."
