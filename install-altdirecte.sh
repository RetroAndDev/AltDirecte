#!/bin/bash

# AltDirecte (macOS) Automatic Installer and Updater

PROJECT_NAME="RetroAndDev/AltDirecte"
ZIP_FILE="AltDirecte-macOS-universal.zip"
APP_NAME="AltDirecte.app"
INSTALL_DIR="/Applications"
SCRIPT_DIR=$(dirname "$(realpath $0)")

function progress {
    while true; do
        echo -n "."
        sleep 1
    done
}

function download_and_install {
    local download_url=$(curl -s "https://api.github.com/repos/$PROJECT_NAME/releases/latest" | grep "browser_download_url.*$ZIP_FILE" | cut -d '"' -f 4)

    if [[ -z $download_url ]]; then
        echo "Impossible de récupérer l'URL de téléchargement depuis GitHub. Vérifiez que le nom du fichier ZIP correspond à celui dans la release."
        exit 1
    fi

    if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
        echo "Suppression de l'ancienne version de l'application..."
        rm -rf "$INSTALL_DIR/$APP_NAME"
    fi

    if [ -f "$SCRIPT_DIR/$ZIP_FILE" ]; then
        echo "Suppression de l'ancien fichier ZIP..."
        rm "$SCRIPT_DIR/$ZIP_FILE"
    fi

    echo "Téléchargement de la dernière version..."
    pushd "$SCRIPT_DIR" > /dev/null
    progress &
    local progress_pid=$!

    curl -# -L -o "$SCRIPT_DIR/$ZIP_FILE" "$download_url"
    kill $progress_pid
    popd > /dev/null

    unzip -q "$SCRIPT_DIR/$ZIP_FILE" -d "$INSTALL_DIR"

    chmod 777 "$INSTALL_DIR/$APP_NAME"
    xattr -r -d com.apple.quarantine "$INSTALL_DIR/$APP_NAME"

    launch_application
}

function install_from_file {
    local_zip=$1

    if [ ! -f "$local_zip" ]; then
        echo "Le fichier ZIP local spécifié n'existe pas : $local_zip"
        exit 1
    fi

    if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
        echo "Suppression de l'ancienne version de l'application..."
        rm -rf "$INSTALL_DIR/$APP_NAME"
    fi

    echo "Extraction de l'application depuis le fichier ZIP local : $local_zip"
    unzip -q "$local_zip" -d "$INSTALL_DIR"

    chmod 777 "$INSTALL_DIR/$APP_NAME"
    xattr -r -d com.apple.quarantine "$INSTALL_DIR/$APP_NAME"

    launch_application
}

function launch_application {
    open "$INSTALL_DIR/$APP_NAME"
}

arg1=$1
arg2=$2
arg3=$3

echo "Argument 0 : $0"
echo "Argument 1 : $1"
echo "Argument 2 : $2"
echo "Argument 3 : $3"


if [ "$arg1" == "" ]; then
    download_and_install
elif [ "$arg1" == "--update" ]; then
    if [ "$arg2" == "" ]; then
        download_and_install
    else
        install_from_file $arg2
    fi
elif [ "$arg1" == "--help" ]; then 
    echo "AltDirecte Installer - Aide"
    echo "Usage : ./install-altdirecte.sh -> Télécharge et installe automatiquement la dernière version"
    echo "Usage : ./install-altdirecte.sh --update <updatefile> -> Installe la version depuis un fichier de MaJ spécifié"
fi

sleep 5
exit