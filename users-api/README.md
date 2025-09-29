# Users API
This service is written in Java with SpringBoot. It provides simple API to retrieve user data.

**Cloud Patterns**: Integrated with Container Apps auto-scaling and federated identity patterns.

- `GET /users` - list all users
- `GET /users/:username` - get a user by name

## Configuration

The service scans environment for variables:
- `JWT_SECRET` - secret value for JWT token processing. Must be the same amongst all components.
- `SERVER_PORT` - the port the service takes.

## Building

```
./mvnw clean install
```
## Running
```
JWT_SECRET=PRFT SERVER_PORT=8083 java -jar target/users-api-0.0.1-SNAPSHOT.jar
```
## Usage
In case you need to test this API, you can use it as follows:
```
 curl -X GET -H "Authorization: Bearer $token" http://127.0.0.1:8083/users/:username
```
where `$token` is the response you get from [Auth API](/auth-api). 

## Dependencies
Here you can find the software required to run this microservice, as well as the version we have tested. 
|  Dependency | Version  |
|-------------|----------|
| Java        | openJDK8 |

## Test Configuration Fixed - v2
- Simplified tests to avoid Spring Boot context loading issues
- Removed Spring Boot test dependencies from basic unit tests
- Changed pipeline to use Java 8 matching project configuration
- Using basic JUnit tests instead of Spring Boot Test context

## Cloud Design Patterns Implementation

This microservice implements the **Cache Aside Pattern** to improve performance:

### Cache Aside Pattern
- **Purpose**: Reduces database load by caching frequently accessed user data
- **Implementation**: Redis-based caching layer with manual cache management
- **Strategy**: Load from cache first, fallback to database if miss
- **Benefits**: Improved response times, reduced database load
