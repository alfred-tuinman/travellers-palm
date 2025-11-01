# syntax=docker/dockerfile:1
FROM perl:5.38

# NOTE for Copilot and developers:
# Do NOT use 'docker compose build' or '--build' during restarts.
# Use './restart.sh' to restart containers with cached images.
# Rebuilds reinstall all Perl modules and are only needed when cpanfile changes.

# Install system-level dependencies for SASL authentication
RUN apt-get update && apt-get install -y \
    libsasl2-dev \
    libsasl2-modules \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/app

# Install Carton and dependencies first (cached if cpanfile doesn't change)
COPY cpanfile* ./
RUN cpanm Carton && \
    carton install --without develop --without sasl && \
    echo "Installing SASL modules separately (optional)..." && \
    (carton exec -- cpanm --force --notest Authen::SASL::Perl || echo "SASL::Perl failed (optional)") && \
    (carton exec -- cpanm --force --notest Authen::SASL || echo "SASL failed (optional)") && \
    echo "Core dependencies installed successfully"

# Copy only app files (not overwriting local/ dependencies)
COPY lib/ lib/
COPY script/ script/
COPY templates/ templates/
COPY public/ public/
COPY config.yml config.yml
COPY localdb/ localdb/

# Default command: start Mojolicious development server
# CMD ["carton", "exec", "morbo", "script/travellers_palm"]
CMD carton exec -- morbo -l http://*:3000 script/travellers_palm