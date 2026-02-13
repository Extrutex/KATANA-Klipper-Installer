#!/bin/bash
# run_verification.sh
# Runs the automated test suite inside the Docker container

# Fix Path for macOS Docker Desktop
export PATH=$PATH:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin

echo "building test container..."
docker build -t katanaos-test -f tests/Dockerfile .

echo "running automated tests..."
docker run --rm katanaos-test /bin/bash -c "chmod +x tests/full_suite.sh && yes | ./tests/full_suite.sh"
