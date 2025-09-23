FROM node:18-alpine AS build
WORKDIR /app

# Instalar Python y herramientas de compilación necesarias para dependencias nativas
RUN apk add --no-cache python3 make g++

COPY package*.json ./

# Corregir versiones de zipkin y reemplazar node-sass por sass
RUN sed -i 's/"zipkin": "[^"]*"/"zipkin": "^0.22.0"/' package.json && \
    sed -i 's/"zipkin-transport-http": "[^"]*"/"zipkin-transport-http": "^0.22.0"/' package.json && \
    sed -i 's/"zipkin-context-cls": "[^"]*"/"zipkin-context-cls": "^0.22.0"/' package.json && \
    sed -i 's/"zipkin-instrumentation-fetch": "[^"]*"/"zipkin-instrumentation-fetch": "^0.22.0"/' package.json && \
    sed -i 's/"zipkin-instrumentation-express": "[^"]*"/"zipkin-instrumentation-express": "^0.22.0"/' package.json && \
    sed -i 's/"node-sass": "[^"]*"/"sass": "^1.69.0"/' package.json

# Eliminar package-lock.json para evitar conflictos
RUN rm -f package-lock.json

# Instalar dependencias
RUN npm install --legacy-peer-deps

COPY . .

# Construir la aplicación
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]