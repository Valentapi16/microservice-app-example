package main

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "time"

    jwt "github.com/dgrijalva/jwt-go"
    "github.com/labstack/echo"
    "github.com/labstack/echo/middleware"
    gommonlog "github.com/labstack/gommon/log"
)

var (
    ErrHttpGenericMessage = echo.NewHTTPError(http.StatusInternalServerError, "something went wrong, please try again later")
    ErrWrongCredentials   = echo.NewHTTPError(http.StatusUnauthorized, "username or password is invalid")
    jwtSecret            = "myfancysecret"
)

func main() {
    // Configuración de puertos corregida según docker-compose
    hostport := ":8080"  // auth-api usa puerto 8080 internamente
    userAPIAddress := "http://users-api:8080"  // users-api en puerto interno 8080

    envJwtSecret := os.Getenv("JWT_SECRET")
    if len(envJwtSecret) != 0 {
        jwtSecret = envJwtSecret
    }

    // Override con variables de entorno si existen
    if port := os.Getenv("AUTH_API_PORT"); port != "" {
        hostport = ":" + port
    }
    if addr := os.Getenv("USERS_API_ADDRESS"); addr != "" {
        userAPIAddress = addr
    }

    // Initialize UserService with Circuit Breaker
    allowedHashes := map[string]interface{}{
        "admin_admin": nil,
        "johnd_foo":   nil,
        "janed_ddd":   nil,
    }
    
    userService := NewUserService(http.DefaultClient, userAPIAddress, allowedHashes)

    e := echo.New()
    e.Logger.SetLevel(gommonlog.INFO)

    // Tracing setup (unchanged)
    if zipkinURL := os.Getenv("ZIPKIN_URL"); len(zipkinURL) != 0 {
        e.Logger.Infof("init tracing to Zipkit at %s", zipkinURL)

        if tracedMiddleware, tracedClient, err := initTracing(zipkinURL); err == nil {
            e.Use(echo.WrapMiddleware(tracedMiddleware))
            userService.Client = tracedClient
        } else {
            e.Logger.Infof("Zipkin tracer init failed: %s", err.Error())
        }
    } else {
        e.Logger.Infof("Zipkin URL was not provided, tracing is not initialised")
    }

    e.Use(middleware.Logger())
    e.Use(middleware.Recover())
    e.Use(middleware.CORS())

    // Health check endpoint
    e.GET("/version", func(c echo.Context) error {
        return c.String(http.StatusOK, "Auth API, written in Go\n")
    })

    // Circuit breaker status endpoint
    e.GET("/health/circuit-breaker", func(c echo.Context) error {
        state := userService.CircuitBreaker.State()
        counts := userService.CircuitBreaker.Counts()
        
        return c.JSON(http.StatusOK, map[string]interface{}{
            "name":           userService.CircuitBreaker.Name(),
            "state":          state.String(),
            "requests":       counts.Requests,
            "totalSuccesses": counts.TotalSuccesses,
            "totalFailures":  counts.TotalFailures,
            "consecutiveSuccesses": counts.ConsecutiveSuccesses,
            "consecutiveFailures":  counts.ConsecutiveFailures,
        })
    })

    e.POST("/login", getLoginHandler(*userService))

    log.Printf("Starting auth-api on %s, connecting to users-api at %s", hostport, userAPIAddress)
    e.Logger.Fatal(e.Start(hostport))
}

// getLoginHandler remains mostly unchanged
func getLoginHandler(userService UserService) echo.HandlerFunc {
    f := func(c echo.Context) error {
        requestData := LoginRequest{}
        decoder := json.NewDecoder(c.Request().Body)
        if err := decoder.Decode(&requestData); err != nil {
            log.Printf("could not read credentials from POST body: %s", err.Error())
            return ErrHttpGenericMessage
        }

        ctx := c.Request().Context()
        user, err := userService.Login(ctx, requestData.Username, requestData.Password)
        if err != nil {
            if err != ErrWrongCredentials {
                log.Printf("could not authorize user '%s': %s", requestData.Username, err.Error())
                return ErrHttpGenericMessage
            }
            return ErrWrongCredentials
        }

        token := jwt.New(jwt.SigningMethodHS256)
        claims := token.Claims.(jwt.MapClaims)
        claims["username"] = user.Username
        claims["firstname"] = user.FirstName
        claims["lastname"] = user.LastName
        claims["role"] = user.Role
        claims["exp"] = time.Now().Add(time.Hour * 72).Unix()

        t, err := token.SignedString([]byte(jwtSecret))
        if err != nil {
            log.Printf("could not generate a JWT token: %s", err.Error())
            return ErrHttpGenericMessage
        }

        return c.JSON(http.StatusOK, map[string]string{
            "accessToken": t,
        })
    }

    return echo.HandlerFunc(f)
}

type LoginRequest struct {
    Username string `json:"username"`
    Password string `json:"password"`
}