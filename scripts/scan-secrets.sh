#!/bin/bash

# Script pour scanner les secrets dans le code avec Gitleaks
# Usage: ./scripts/scan-secrets.sh [options]

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Scan des secrets avec Gitleaks...${NC}"

# Vérifier si gitleaks est installé
if ! command -v gitleaks &> /dev/null; then
    echo -e "${RED}❌ Gitleaks n'est pas installé${NC}"
    echo -e "${YELLOW}📦 Installation de Gitleaks...${NC}"
    echo ""
    echo "Options d'installation:"
    echo "  - macOS/Linux: brew install gitleaks"
    echo "  - Windows: scoop install gitleaks"
    echo "  - Voir: https://github.com/gitleaks/gitleaks#installation"
    echo ""
    exit 1
fi

# Vérifier la version
echo -e "${GREEN}✅ Gitleaks installé: $(gitleaks version)${NC}"
echo ""

# Options par défaut
MODE="detect"
VERBOSE="--verbose"
SOURCE="."

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --protect)
            MODE="protect"
            shift
            ;;
        --staged)
            MODE="detect-staged"
            shift
            ;;
        --quiet)
            VERBOSE=""
            shift
            ;;
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --protect     Mode protect (pour pre-commit hooks)"
            echo "  --staged      Scanner uniquement les fichiers stagés"
            echo "  --quiet       Mode silencieux"
            echo "  --source DIR  Répertoire à scanner (défaut: .)"
            echo "  --help        Afficher cette aide"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Option inconnue: $1${NC}"
            echo "Utilisez --help pour voir les options disponibles"
            exit 1
            ;;
    esac
done

# Exécuter le scan
case $MODE in
    detect)
        echo -e "${GREEN}📊 Scan du repository complet...${NC}"
        gitleaks detect --source "$SOURCE" $VERBOSE
        ;;
    detect-staged)
        echo -e "${GREEN}📊 Scan des fichiers stagés...${NC}"
        gitleaks detect --no-git --source "$SOURCE" $VERBOSE
        ;;
    protect)
        echo -e "${GREEN}🛡️  Mode protect (recommandé pour pre-commit)...${NC}"
        gitleaks protect $VERBOSE
        ;;
esac

# Vérifier le code de sortie
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Aucun secret détecté${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Des secrets ont été détectés !${NC}"
    echo -e "${YELLOW}⚠️  Veuillez corriger les problèmes avant de commiter${NC}"
    exit $EXIT_CODE
fi




