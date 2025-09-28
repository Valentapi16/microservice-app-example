FROM node:18-alpine AS build
WORKDIR /app

# Instalar Python y herramientas de compilación necesarias para dependencias nativas
RUN apk add --no-cache python3 make g++

COPY package*.json ./

# Corregir versiones de zipkin
RUN sed -i 's/"zipkin": "[^"]*"/"zipkin": "^0.22.0"/' package.json

# Eliminar package-lock.json para evitar conflictos
RUN rm -f package-lock.json

# Instalar dependencias (incluyendo devDependencies para el build)
RUN npm install --legacy-peer-deps --include=dev

COPY . .

# Construir la aplicación
RUN npm run build 2>&1 | tee build.log

# Verificar si el build fue exitoso y si existe dist
RUN cat build.log && ls -la /app/

FROM nginx:stable-alpine

# Copiar archivos build al directorio de nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Crear configuración de nginx con proxies
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Servir archivos estáticos directamente \
    location /static/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    \
    # Proxy para login \
    location /login { \
        proxy_pass http://auth-api:8080; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_pass_request_headers on; \
    } \
    \
    # Proxy para todos \
    location /todos { \
        proxy_pass http://todos-api:8080; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_pass_request_headers on; \
    } \
    \
    # Fallback para SPA (Single Page Application) \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]