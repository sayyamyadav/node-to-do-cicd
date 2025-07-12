# Stage 1 - Build Stage
FROM node:18-alpine AS builder

# SET A WORK DIRECTORY
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./

RUN npm install 
# Copy the source code
COPY . .

# Copy the source code

# Stage 2 -  Production Stage using distroless image
FROM gcr.io/distroless/nodejs18-debian11

# Non ROOT User -distroless image by deafault don't use root user
USER nonroot

# Set working directory
WORKDIR /app

# Copy compiled app and node_modules from builder
COPY --from=builder /app /app


# Expose the port
EXPOSE 8000

# Start the app
CMD ["node", "app.js"]

