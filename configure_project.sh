#!/bin/bash

# Configuration Script for MantraFlow
# Updates the Development Team ID and Bundle Identifier Prefix in the Xcode project.

PROJECT_FILE="MantraFlow.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

echo "----------------------------------------------------"
echo "           MantraFlow Configuration Setup           "
echo "----------------------------------------------------"
echo ""

# 1. Get Development Team ID
read -p "Enter your Apple Development Team ID (e.g., A1B2C3D4E5): " TEAM_ID

if [ -z "$TEAM_ID" ]; then
    echo "Error: Team ID cannot be empty."
    exit 1
fi

# 2. Get Bundle Prefix
read -p "Enter your Organization Bundle Identifier Prefix [com.marcodeb]: " BUNDLE_PREFIX
BUNDLE_PREFIX=${BUNDLE_PREFIX:-com.marcodeb}

echo ""
echo "Updating project configuration..."
echo "  - Team ID: $TEAM_ID"
echo "  - Bundle Prefix: $BUNDLE_PREFIX"
echo ""

# Create a backup
cp "$PROJECT_FILE" "$PROJECT_FILE.bak"
echo "Backup created at $PROJECT_FILE.bak"

# 3. Apply Changes using sed
# Update Development Team
sed -i '' "s/DEVELOPMENT_TEAM = [A-Z0-9]*;/DEVELOPMENT_TEAM = $TEAM_ID;/g" "$PROJECT_FILE"

# Update Bundle Identifier
# This regex looks for PRODUCT_BUNDLE_IDENTIFIER = <something>; and replaces the prefix
# It assumes the structure is prefix.MantraFlow or prefix.MantraFlow.MantraWidget
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*MantraFlow/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_PREFIX.MantraFlow/g" "$PROJECT_FILE"

echo "✅ Configuration updated successfully!"
echo "You can now open MantraFlow.xcodeproj in Xcode."
