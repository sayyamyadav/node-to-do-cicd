# Stage 1 - Build Stage
#FROM node:18-alpine AS builder
FROM node:18-bullseye-slim AS builder

# SET A WORK DIRECTORY
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./

RUN npm install 
# Copy the source code
COPY . .

# Copy the source code

# Stage 2 -  Production Stage using distroless image
FROM gcr.io/distroless/nodejs18-debian11:nonroot


# Non ROOT User -distroless image by deafault don't use root user
USER nonroot

# Set working directory
WORKDIR /app

# Copy compiled app and node_modules from builder
COPY --from=builder /app /app


# Expose the port
EXPOSE 8000

# ✅ FIX: Add HEALTHCHECK for container runtime checks
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8000/health || exit 1

# Start the app
CMD ["node", "app.js"]

