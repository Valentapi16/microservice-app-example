FROM golang:1.20-alpine AS build
WORKDIR /src
COPY . .
RUN go mod init auth-api
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o /auth-api .

FROM alpine:3.18
COPY --from=build /auth-api /auth-api
EXPOSE 8080
CMD ["/auth-api"]