# syntax=docker/dockerfile:1
FROM perl:5.38

# NOTE for Copilot and developers:
# Do NOT use 'docker compose build' or '--build' during restarts.
# Use './restart.sh' to restart containers with cached images.
# Rebuilds reinstall all Perl modules and are only needed when cpanfile changes.

# Set working directory
WORKDIR /usr/src/app

# Install Carton and dependencies first (cached if cpanfile doesn’t change)
COPY cpanfile* ./
RUN cpanm Carton && carton install --deployment

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