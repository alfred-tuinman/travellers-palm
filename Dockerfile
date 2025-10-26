# Base Perl image
FROM perl:5.38

ENV PERL_MM_USE_DEFAULT=1
ENV PERL_CPANM_OPT="--notest"
ENV CARTON_HOME=/usr/src/app/carton_cache

# Install system packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      tzdata build-essential make gcc \
      libsqlite3-dev libssl-dev unzip wget && \
    ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime && \
    echo "Asia/Bangkok" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Carton
RUN cpanm --notest Carton

# Set working directory
WORKDIR /usr/src/app

# Create runtime folders
RUN mkdir -p log data carton_cache

# ----------------------------
# Install dependencies (cacheable)
# ----------------------------

# Copy only cpanfile & snapshot first (this layer rebuilds only if they change)
COPY cpanfile ./ 
COPY cpanfile.snapshot ./ 

# Install modules using the snapshot
RUN carton install --deployment --without development

# ----------------------------
# Copy application code (separate layer)
# ----------------------------
COPY lib/ lib/
COPY script/ script/
COPY templates/ templates/
COPY public/ public/
COPY config.yml config.yml
COPY localdb/ localdb/

# Make startup script executable
RUN chmod +x script/travellers_palm

# Expose port
EXPOSE 3000

# Default command: development mode with hot reload
CMD ["carton", "exec", "--", "morbo", "-l", "http://*:3000", "script/travellers_palm"]
