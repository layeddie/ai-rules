#!/bin/bash
# Docker entrypoint for ai-rules development environment

set -e

# Source asdf if available
if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
fi

# Install dependencies if mix.exs exists
if [ -f "/app/mix.exs" ] && [ ! -d "/app/_build" ]; then
    echo "Installing dependencies..."
    cd /app
    mix deps.get
    mix compile
fi

# Execute the command
exec "$@"
