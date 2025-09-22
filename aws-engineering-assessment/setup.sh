#!/bin/bash
set -e

sudo apt update

sudo apt install -y python3

sudo apt install -y python3-pip

#https://stackoverflow.com/questions/52359805/is-sys-version-info-reliable-for-python-version-checking
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "Installing venv for Python $PYTHON_VERSION..."
sudo apt install -y "python${PYTHON_VERSION}-venv"

VENV_NAME="awscli_venv"
echo "Creating virtual environment: $VENV_NAME"
python3 -m venv "$VENV_NAME"

echo "Upgrading pip inside virtual environment."
"$VENV_NAME/bin/pip" install --upgrade pip

echo "Installing AWS CLI v1..."
"$VENV_NAME/bin/pip" install "awscli<2.0"


echo "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

echo "Setup complete!"
echo "You can now use the AWS CLI inside the virtual environment."
