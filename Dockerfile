FROM perl:5.38-slim

# Install system dependencies to build Perl modules
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc \
    libsqlite3-dev \
    libssl-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Perl dependencies from cpanfile
COPY cpanfile .
RUN cpanm --notest --installdeps .

# Set this before the copy commands!
WORKDIR /usr/src/app

# Copy app code
COPY . .

EXPOSE 5000

# Run Starman
CMD ["plackup", "-s", "Starman", "--workers", "4", "--port", "5000", "app.psgi"]
