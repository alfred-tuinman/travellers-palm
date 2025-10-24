FROM perl:5.38

# Install tzdata (Debian/Ubuntu style)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime && \
    echo "Asia/Bangkok" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install basic build tools and SQLite development headers
RUN apt-get update && apt-get install -y \
      build-essential \
      make \
      gcc \
      libsqlite3-dev \
      libssl-dev \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Install cpanminus modules
RUN cpanm --notest Carton

# Set work directory
WORKDIR /usr/src/app

# Copy cpanfile first (so Docker can cache dependencies)
COPY cpanfile cpanfile
RUN cpanm --notest --installdeps .

# Install all modules in cpanfile
# RUN carton install --deployment

# Copy app code
COPY lib/ lib/
COPY script/ script/
COPY templates/ templates/
COPY public/ public/
COPY config.yml config.yml
COPY localdb/ localdb/

# COPY localdb/Jadoo_2006.db localdb/Jadoo_2006.db

# Install all modules in cpanfile
# RUN carton install --deployment

# Make startup script executable
RUN chmod +x script/travellers_palm

# create directory for db
RUN mkdir -p /usr/src/app/data

# Expose the Mojolicious port
EXPOSE 3000

# development mode with morbo
CMD ["morbo", "script/travellers_palm"]

# Run hypnotoad in production
# CMD ["hypnotoad", "script/travellers_palm"]