FROM node:20.15.0-buster

# Create app directory and set permissions
RUN mkdir -p /app && chown -R node:node /app

# Copy application files to /app
COPY ./ /app

# Update packages and install necessary dependencies including Redis
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  libpango1.0-dev \
  libcairo2-dev \
  libjpeg-dev \
  libgif-dev \
  librsvg2-dev \
  pkg-config \
  python3 && \
  rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install PM2 globally
RUN npm install pm2 -g

# Install pnpm and dependencies, then build the project
RUN npm install

# Expose the application port
EXPOSE 3000

ENTRYPOINT ["bash", "-c", "pm2 --name node-sample start npm -- run dev && /bin/bash"]

