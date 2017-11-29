if [ "$EUID" == 0 ]; then
    echo "Warning! This script is meant to be ran as a user!"
    read -r -p "Are you sure you want to run it as root? [y/N] " response
    response=${response,,}
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        echo "Ok, continuing."
    else
        exit 0
    fi
fi
unset "CDPATH"
echo "Starting Apex Sigma installation."
echo "Installing required APT packages..."
sudo apt-get -qq install -y git ffmpeg build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
echo "Installing Python 3.6.3..."
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tgz
sudo tar xzf Python-3.6.3.tgz
cd Python-3.6.3
sudo ./configure
sudo make altinstall
echo "Installing MongoDB..."
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get -qq install -y mongodb-org
sudo systemctl start mongod
echo "Pulling Sigma's respository..."
cd ~
git clone https://github.com/lu-ci/apex-sigma-core.git
cd apex-sigma-core
echo "Creating VENV"
python3.6 -m venv .venv
echo "Installing PIP modules..."
source ".venv/bin/activate"
pip install -Ur requirements.txt
pip install -Ur requirements-linux.txt
echo "Installation complete."
echo "Please go to /srv/apex-sigma-core and run Sigma using run.sh"
echo "Have fun~"
exit