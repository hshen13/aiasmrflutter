# Stage 1: Build Flutter web app
FROM dart:stable AS builder

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

WORKDIR /app
COPY . .

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl

# Build with environment variables
ARG BACKEND_URL
ENV BACKEND_URL=$BACKEND_URL

RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app using nginx
FROM nginx:alpine

# Install curl and bash for healthcheck and wait script
RUN apk add --no-cache curl bash

# Copy wait-for script
COPY wait-for-backend.sh /wait-for-backend.sh
RUN chmod +x /wait-for-backend.sh

# Copy the built web app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost || exit 1

EXPOSE 80

# Wait for backend before starting nginx
CMD ["/bin/bash", "-c", "/wait-for-backend.sh backend:8000 -- nginx -g 'daemon off;'"]
