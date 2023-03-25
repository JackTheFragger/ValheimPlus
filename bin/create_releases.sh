#!/bin/bash
# run from the ValheimPlus repo root dir

# Update this as necessary:
BEPINEXPACK_VALHEIM_VERSION="5.4.2100"

# Constants:
VERSION=$(grep "public const string version" ValheimPlus/ValheimPlus.cs | cut -f2 -d'"')
OUTPUT_DIR=$(realpath "release/$VERSION")
TEMP_DIR="release/temp"
VALHEIM_PLUS_DLL="ValheimPlus\bin\Debug\ValheimPlus.dll"
BEPINEXPACK_VALHEIM_TEMP_DIR="$TEMP_DIR/denikson-BepInExPack_Valheim"
BEPINEXPACK_VALHEIM_DOWNLOAD_URL="https://gcdn.thunderstore.io/live/repository/packages/denikson-BepInExPack_Valheim-$BEPINEXPACK_VALHEIM_VERSION.zip"

YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Prompt with version info
echo "This will build release files for ValheimPlus with the following options":
echo -e "${YELLOW}Valheim Plus version        = $VERSION"
echo -e "BepInExPack_Valheim version = $BEPINEXPACK_VALHEIM_VERSION${NC}"
while true; do
    read -p "Proceed? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Clear and recreate dirs
rm -rf "$OUTPUT_DIR" "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# move simple files
cp "valheim_plus.cfg" "$OUTPUT_DIR"
cp "$VALHEIM_PLUS_DLL" "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Couldn't find the ValheimPlus.dll $BEPINEXPACK_VALHEIM_VERSION${NC}" 1>&2
    exit 1
fi

# Create Bepinex bundle
BEPINEXPACK_VALHEIM_ZIP_FILE="$TEMP_DIR/denikson-BepInExPack_Valheim.zip"
curl -fso "$BEPINEXPACK_VALHEIM_ZIP_FILE" "$BEPINEXPACK_VALHEIM_DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo -e "${RED}Couldn't download BepInExPack_Valheim version $BEPINEXPACK_VALHEIM_VERSION${NC}" 1>&2
    exit 1
fi

unzip -q "$BEPINEXPACK_VALHEIM_ZIP_FILE" -d "$BEPINEXPACK_VALHEIM_TEMP_DIR"
cp "$VALHEIM_PLUS_DLL" "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/BepInEx/plugins/ValheimPlus.dll"

# trim down files to just those needed for Unix.
rm "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/changelog.txt"

# create unix zips
( \
    cd "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/" \
        && zip -qr "$OUTPUT_DIR/UnixServer.zip" . \
        && tar -czf "$OUTPUT_DIR/UnixServer.tar.gz" * \
)

# Trim down to windows files
rm "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/start_game_bepinex.sh"
rm "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/start_server_bepinex.sh"

# create windows zips
( \
    cd "$BEPINEXPACK_VALHEIM_TEMP_DIR/BepInExPack_Valheim/" \
        && zip -qr "$OUTPUT_DIR/WindowsServer.zip" . \
        && tar -czf "$OUTPUT_DIR/WindowsServer.tar.gz" * \
)

cp "$OUTPUT_DIR/WindowsServer.zip" "$OUTPUT_DIR/WindowsClient.zip"
cp "$OUTPUT_DIR/WindowsServer.tar.gz" "$OUTPUT_DIR/WindowsClient.tar.gz"

# Vortex zip
VORTEX="$TEMP_DIR/Vortex/"
VORTEX_PLUGINS="$VORTEX/plugins"
mkdir -p "$VORTEX_PLUGINS"
cp "$VALHEIM_PLUS_DLL" "$VORTEX_PLUGINS"
(cd "$VORTEX" && zip -qr "$OUTPUT_DIR/Vortex.zip" .)

# Thunderstore zip
THUNDERSTORE="$TEMP_DIR/Thunderstore"
THUNDERSTORE_PLUGINS="$THUNDERSTORE/BepInEx/plugins"
mkdir -p "$THUNDERSTORE_PLUGINS"
cp "resources/images/icon.png" "$THUNDERSTORE"
cp "README.md" "$THUNDERSTORE"
cp "$VALHEIM_PLUS_DLL" "$THUNDERSTORE_PLUGINS"

cat <<EOF > "$THUNDERSTORE/manifest.json"
{
    "name": "ValheimPlus_Grantapher_Temporary",
    "version_number": "$(echo "$VERSION" | cut -d'.' -f2-)",
    "website_url": "https://discord.gg/XamVGpgnJT",
    "description": "A temporary Valheim Plus fork by Grantapher while we wait for the main mod to be updated.",
    "dependencies": [
        "denikson-BepInExPack_Valheim-$BEPINEXPACK_VALHEIM_VERSION"
    ]
}
EOF

(cd "$THUNDERSTORE" && zip -qr "$OUTPUT_DIR/Thunderstore.zip" .)

rm -rf "$TEMP_DIR"