FROM node:18-alpine AS build
WORKDIR /app

# Instalar Python y herramientas de compilación
RUN apk add --no-cache python3 make g++

COPY package*.json ./

# Corregir versiones de zipkin
RUN sed -i 's/"zipkin": "[^"]*"/"zipkin": "^0.22.0"/' package.json

# Eliminar package-lock.json para evitar conflictos
RUN rm -f package-lock.json

# Instalar dependencias
RUN npm install --legacy-peer-deps --include=dev

COPY . .

# Construir la aplicación
RUN npm run build

FROM nginx:stable-alpine

# Instalar envsubst
RUN apk add --no-cache gettext

# Copiar archivos build
COPY --from=build /app/dist /usr/share/nginx/html

# Crear configuración nginx template con variables de entorno
COPY <<EOF /etc/nginx/templates/default.conf.template
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    
    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;
    proxy_ssl_verify off;
    proxy_ssl_session_reuse off;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
    
    location /login {
        proxy_pass https://ca-auth-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io/login;
        proxy_set_header Host ca-auth-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Authorization \$http_authorization;
        proxy_pass_request_headers on;
        proxy_ssl_server_name on;
    }
    
    location /todos {
        proxy_pass https://ca-todos-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io;
        proxy_set_header Host ca-todos-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Authorization \$http_authorization;
        proxy_set_header Content-Type \$content_type;
        proxy_pass_request_headers on;
        proxy_pass_request_body on;
        proxy_ssl_server_name on;
        proxy_buffering off;
    }
    
    location /users {
        proxy_pass https://ca-users-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io;
        proxy_set_header Host ca-users-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Authorization \$http_authorization;
        proxy_set_header Content-Type \$content_type;
        proxy_pass_request_headers on;
        proxy_pass_request_body on;
        proxy_ssl_server_name on;
        proxy_buffering off;
    }
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]