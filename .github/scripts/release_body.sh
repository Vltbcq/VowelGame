#!/usr/bin/env bash
# Description d'une Release : ce qui compte le plus pour le joueur d'abord, + lien vers le changelog.
# Usage : release_body.sh <version> [--short]   (écrit sur la sortie standard)
# - Résumé écrit à la main : .github/release-notes/<version>.md, en 2 parties :
#     « ## À la une » (3 à 5 points forts, mis en avant) puis « ## Le reste » (dans un bloc à déplier).
#   --short (annonce Discord) : seulement la une.
#   Ancien format (sans ces titres) : les 5 premières lignes.
# - Sans résumé : les 4 derniers titres de commits, puis « … et N autres changements »
set -euo pipefail
VERSION="$1"
SHORT="0"
if [ "${2:-}" = "--short" ]; then SHORT="1"; fi
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

NOTES=".github/release-notes/$VERSION.md"
if [ -f "$NOTES" ] && grep -q '^## À la une' "$NOTES"; then
  # Format « À la une » + « Le reste » : la une est mise en avant, le reste se déplie
  echo "## ✨ À la une"
  sed -n '/^## À la une/,/^## /p' "$NOTES" | sed '/^## /d; /^[[:space:]]*$/d'
  REST=$(sed -n '/^## Le reste/,$p' "$NOTES" | sed '/^## /d; /^[[:space:]]*$/d')
  if [ "$SHORT" != "1" ] && [ -n "$REST" ]; then
    echo
    echo "<details><summary>Voir tous les changements ($(echo "$REST" | wc -l | tr -d ' '))</summary>"
    echo
    echo "$REST"
    echo
    echo "</details>"
  fi
elif [ -f "$NOTES" ]; then
  echo "## Nouveautés"
  sed '/^[[:space:]]*$/d' "$NOTES" | head -n 5
else
  echo "## Nouveautés"
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
echo "▶ Télécharge \`PaintIt.exe\` (ou \`PaintIt-windows.zip\`, plus léger). Si Windows bloque : *Informations complémentaires* → *Exécuter quand même*."
