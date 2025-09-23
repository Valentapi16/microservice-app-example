package main

import (
    "context"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"
    "time"

    jwt "github.com/dgrijalva/jwt-go"
    "github.com/sony/gobreaker"
)

var allowedUserHashes = map[string]interface{}{
    "admin_admin": nil,
    "johnd_foo":   nil,
    "janed_ddd":   nil,
}

type User struct {
    Username  string `json:"username"`
    FirstName string `json:"firstname"`
    LastName  string `json:"lastname"`
    Role      string `json:"role"`
}

type HTTPDoer interface {
    Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
    Client            HTTPDoer
    UserAPIAddress    string
    AllowedUserHashes map[string]interface{}
    CircuitBreaker    *gobreaker.CircuitBreaker  // Circuit Breaker
}

// Initialize Circuit Breaker for UserService
func NewUserService(client HTTPDoer, userAPIAddress string, allowedHashes map[string]interface{}) *UserService {
    // Circuit Breaker Settings
    cbSettings := gobreaker.Settings{
        Name:        "UserAPI-CircuitBreaker",
        MaxRequests: 3,                    // Max requests allowed when half-open
        Interval:    time.Duration(30) * time.Second,  // Reset interval
        Timeout:     time.Duration(60) * time.Second,  // Timeout to switch to half-open
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            // Trip when failure rate >= 60% and at least 5 requests
            failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
            return counts.Requests >= 5 && failureRatio >= 0.6
        },
        OnStateChange: func(name string, from gobreaker.State, to gobreaker.State) {
            fmt.Printf("Circuit Breaker '%s' changed from %s to %s\n", name, from, to)
        },
    }

    return &UserService{
        Client:            client,
        UserAPIAddress:    userAPIAddress,
        AllowedUserHashes: allowedHashes,
        CircuitBreaker:    gobreaker.NewCircuitBreaker(cbSettings),
    }
}

func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
    user, err := h.getUser(ctx, username)
    if err != nil {
        return user, err
    }

    userKey := fmt.Sprintf("%s_%s", username, password)

    if _, ok := h.AllowedUserHashes[userKey]; !ok {
        return user, ErrWrongCredentials
    }

    return user, nil
}

func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
    var user User

    // Execute HTTP call through Circuit Breaker
    result, err := h.CircuitBreaker.Execute(func() (interface{}, error) {
        return h.getUserWithCircuitBreaker(ctx, username)
    })

    if err != nil {
        // Circuit breaker is open or half-open failed
        fmt.Printf("Circuit breaker error for user %s: %v\n", username, err)
        
        // Fallback: return a basic user with limited info
        if err == gobreaker.ErrOpenState {
            fmt.Println("Circuit breaker is OPEN - using fallback")
            return User{
                Username:  username,
                FirstName: "Unknown",
                LastName:  "User",
                Role:      "basic",
            }, nil
        }
        
        return user, err
    }

    user = result.(User)
    return user, nil
}

func (h *UserService) getUserWithCircuitBreaker(ctx context.Context, username string) (User, error) {
    var user User

    token, err := h.getUserAPIToken(username)
    if err != nil {
        return user, err
    }

    url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Add("Authorization", "Bearer "+token)
    req = req.WithContext(ctx)

    // Add timeout to the request
    ctxWithTimeout, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    req = req.WithContext(ctxWithTimeout)

    resp, err := h.Client.Do(req)
    if err != nil {
        return user, fmt.Errorf("failed to call users API: %w", err)
    }
    defer resp.Body.Close()

    bodyBytes, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return user, fmt.Errorf("failed to read response body: %w", err)
    }

    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        return user, fmt.Errorf("users API returned error %d: %s", resp.StatusCode, string(bodyBytes))
    }

    err = json.Unmarshal(bodyBytes, &user)
    if err != nil {
        return user, fmt.Errorf("failed to unmarshal user data: %w", err)
    }

    return user, nil
}

func (h *UserService) getUserAPIToken(username string) (string, error) {
    token := jwt.New(jwt.SigningMethodHS256)
    claims := token.Claims.(jwt.MapClaims)
    claims["username"] = username
    claims["scope"] = "read"
    return token.SignedString([]byte(jwtSecret))
}