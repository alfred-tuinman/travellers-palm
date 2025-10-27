FROM perl:5.38

# Set working directory
WORKDIR /usr/src/app

# Set timezone
ENV TZ=Asia/Bangkok

RUN apt-get update && apt-get install -y tzdata \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Carton and dependencies first (cached layer)
COPY cpanfile cpanfile.snapshot ./
RUN cpanm Carton && carton install --deployment

# Copy only your app code afterward
COPY lib/ lib/
COPY script/ script/
COPY templates/ templates/
COPY public/ public/
COPY config.yml config.yml
COPY localdb/ localdb/

# Expose port and run app
EXPOSE 3000
CMD ["carton", "exec", "morbo", "script/travellers_palm"]
