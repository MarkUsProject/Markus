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
[ -f ./venv/bin/python3 ] || python3 -m venv ./venv
./venv/bin/python3 -m pip install -q --upgrade pip
printf "[MarkUs] Running pip install -q -r requirements-jupyter.txt..."
if ./venv/bin/python3 -m pip install -q -r requirements-jupyter.txt; then
  printf " \e[32m✔\e[0m \n"
fi
printf "[MarkUs] Running pip install -q -r requirements-scanner.txt..."
if ./venv/bin/python3 -m pip install -q -r requirements-scanner.txt; then
  printf " \e[32m✔\e[0m \n"
fi
printf "[MarkUs] Running pip install -q -r requirements-qr.txt..."
if ./venv/bin/python3 -m pip install -q -r requirements-qr.txt; then
  printf " \e[32m✔\e[0m \n"
fi

# Install chromium (for nbconvert webpdf conversion)
printf "[MarkUs] Running playwright install chromium..."
if ./venv/bin/python3 -m playwright install chromium; then
  printf " \e[32m✔\e[0m \n"
fi

# Execute the provided command
exec "$@"
