# ai-rules Development Environment
#
# This Dockerfile creates a complete development environment for ai-rules
# with Elixir, Erlang, and all required tooling pre-installed.
#
# Build: docker build -t ai-rules-dev -f tools/setup/Dockerfile .
# Run:   docker run -it -v $(pwd):/app ai-rules-dev
#
# Or use docker-compose for easier management.

FROM elixir:1.16.1-otp-26

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    inotify-tools \
    nodejs \
    npm \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# Install asdf for version management
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1 && \
    echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install common Elixir tools
RUN mix archive.install hex phx_new 1.7.10 --force || true

# Set up working directory
WORKDIR /app

# Create non-root user
RUN useradd -m -s /bin/bash developer && \
    chown -R developer:developer /app

USER developer

# Configure shell
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc

# Copy entrypoint
COPY --chown=developer:developer tools/setup/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
