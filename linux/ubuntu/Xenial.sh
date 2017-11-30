#!/usr/bin/env bash

unset CDPATH

# Helper functions

abort() {
    local message="${1:-}"
    local exit_code="${2:-1}"

    [ "$message" == "" ] || echo "$message"
    exit "$exit_code"
}

root_check() {
    [ "$EUID" -eq 0 ] || return 0

    echo "Warning! This script is meant to be ran as a user!"
    read -r -p "Are you sure you want to run it as root? [y/N] " response

    case "$response" in
        y*|Y*) echo "Ok, continuing." ;;
        *)     exit 1 ;;
    esac
}

safe_cd() {
    cd "$1" || abort "Failed to change directory to $1"
}

# Setup

root_check

echo "Starting Apex Sigma installation."

echo "Installing required APT packages..."
system_deps=(
    git ffmpeg build-essential checkinstall libsystemd-dev
    libreadline-gplv2-dev libncursesw5-dev libssl-dev
    libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
)
(sudo apt-get update -qq && sudo apt-get -qq install -y ${system_deps[*]}) \
|| abort "Failed to install system dependencies"

echo "Installing Python 3.6.3..."
(safe_cd /usr/src \
    && sudo wget https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tgz \
    && sudo tar xzf Python-3.6.3.tgz \
    && safe_cd Python-3.6.3 \
    && sudo ./configure \
    && sudo make altinstall) \
|| abort "Failed to install Python"

echo "Installing MongoDB..."
(sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
    && (echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" \
        | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list) \
    && sudo apt-get update && sudo apt-get -qq install -y mongodb-org \
    && sudo systemctl start mongod) \
|| abort "Failed to install MongoDB"

echo "Pulling Sigma's respository..."
safe_cd ~
git clone https://github.com/lu-ci/apex-sigma-core.git \
|| abort "Failed to clone repository"

echo "Creating VENV"
safe_cd apex-sigma-core
python3.6 -m venv .venv \
|| abort "Failed to create VENV"

echo "Installing PIP modules..."
(source ".venv/bin/activate" \
    && pip install -Ur requirements.txt \
    && pip install -Ur requirements-linux.txt) \
|| abort "Failed to install PIP modules"

echo "Installation complete."
echo "Please go to /srv/apex-sigma-core and run Sigma using run.sh"
echo "Have fun~"
