#!/bin/sh

# exit script if any command fails
set -e

echo 'Provisioning Macbook...'
echo '\n\n'

if [[ $(/usr/bin/gcc 2>&1) =~ "o developer tools were found" ]] || [[ ! -x /usr/bin/gcc ]]; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install

    echo "Press any key when the installation has finished."
    read -n 1

    if [[ $(/usr/bin/gcc 2>&1) =~ "o developer tools were found" ]] || [[ ! -x /usr/bin/gcc ]]; then
        echo "Oh you dirty liar! You didn't install the Xcode Command Line Tools! Terminating :("
        exit 1
    fi
fi

#check if brew is installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! ls /Applications | grep -q "1Password"; then
    echo "1Password is missing. Installing..."
    brew install --cask 1password
    brew install 1password-cli

    echo "Go login to 1Password and configure it:"
    echo "1Password -> Settings -> Security -> Touch ID"
    echo "1Password -> Settings -> Developer -> Connect with 1Password CLI"
    echo "1Password -> Settings -> Developer -> Use SSH Agent"

    echo "Press any key when you're done."
    read -n 1
    
    mkdir -p ~/.ssh
    echo "Host *\n  IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"" > ~/.ssh/config
fi

mkdir -p ~/dev/git
cd ~/dev/git

if [[ ! -d 'macsetup' ]]; then
  echo "Cloning Mac Setup git repository..."
  git clone --recursive git@github.com:paveldudka/macsetup.git
else
  echo "Found Mac Setup git repository. Skipping git clone..."
  cd ~/dev/git/macsetup
  git pull --recurse-submodules
fi

source ~/dev/git/macsetup/dotfiles/.exports

echo "Installing Ansible..."
brew install python3

echo "Installing PipEnv..."
python3 -m pip install pipenv

echo "Running Ansible playbook..."
cd ~/dev/git/macsetup/ansible

pipenv install
pipenv run ansible-playbook -i inventory/prod local.yml

echo "Success!"