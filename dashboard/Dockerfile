# =========================
# Build stage
# =========================
FROM node:20-alpine AS builder

WORKDIR /app

# Copier uniquement les fichiers de dépendances
COPY package*.json ./

# Installer toutes les dépendances (y compris dev)
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm ci && \
    npm cache clean --force

# Copier le reste du code
COPY . .

# Argument pour l’API backend
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Construire le projet React
RUN npm run build

# =========================
# Production stage
# =========================
FROM nginx:1.25-alpine

# Copier le build dans nginx
COPY --from=builder /app/build /usr/share/nginx/html

# Définir le propriétaire des fichiers
RUN chown -R nginx:nginx /usr/share/nginx/html

EXPOSE 80

# Healthcheck basique
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
