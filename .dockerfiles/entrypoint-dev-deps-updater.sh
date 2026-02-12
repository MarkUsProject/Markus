#!/usr/bin/env bash
# This script updates all MarkUs non-system dependencies

# Install bundle gems
printf "[MarkUs] Checking Ruby dependencies..."
if ! bundle check &> /dev/null; then
  printf "\n[MarkUs] Not all Ruby dependencies are installed. Running bundle install:\n"
  bundle install
else
  printf " \e[32m✔\e[0m \n"
fi

# Install node packages
printf "[MarkUs] Checking Javascript dependencies..."
if ! npm list &> /dev/null; then
  printf "\n[MarkUs] Not all Javascript dependencies are installed. Running npm install:\n"
  npm install
else
  printf " \e[32m✔\e[0m \n"
fi

# Install Python packages
PYTHON_EXE=./venv/bin/python3.13
[ -f $PYTHON_EXE ] || python3.13 -m venv ./venv
$PYTHON_EXE -m pip install -q --upgrade pip
$PYTHON_EXE -m pip install -q uv
printf "[MarkUs] Running $PYTHON_EXE -m pip install -q -r requirements-jupyter.txt..."
if $PYTHON_EXE -m pip install -q -r requirements-jupyter.txt; then
  printf " \e[32m✔\e[0m \n"
fi
printf "[MarkUs] Running $PYTHON_EXE -m pip install -q -r requirements-scanner.txt..."
if $PYTHON_EXE -m pip install --extra-index-url https://download.pytorch.org/whl/cpu -r requirements-scanner.txt; then
  printf " \e[32m✔\e[0m \n"
fi

# Install chromium (for nbconvert webpdf conversion)
printf "[MarkUs] Running $PYTHON_EXE -m playwright install chromium..."
if $PYTHON_EXE -m playwright install chromium; then
  printf " \e[32m✔\e[0m \n"
fi

# Execute the provided command
exec "$@"
