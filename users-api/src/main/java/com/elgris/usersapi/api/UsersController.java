package com.elgris.usersapi.api;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.LinkedList;
import java.util.List;

@RestController()
@RequestMapping("/users")
public class UsersController {

    @Autowired
    private UserRepository userRepository;


    @RequestMapping(value = "/", method = RequestMethod.GET)
    public List<User> getUsers() {
        List<User> response = new LinkedList<>();
        userRepository.findAll().forEach(response::add);

        return response;
    }

    @RequestMapping(value = "/{username}",  method = RequestMethod.GET)
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {

        Object requestAttribute = request.getAttribute("claims");
        
        // Allow access without JWT for inter-service communication
        if (requestAttribute == null) {
            System.out.println("DEBUG: No JWT claims found, allowing inter-service access for user: " + username);
            return userRepository.findOneByUsername(username);
        }

        if (!(requestAttribute instanceof Claims)) {
            throw new RuntimeException("Did not receive required data from JWT token");
        }

        Claims claims = (Claims) requestAttribute;

        String tokenUsername = (String) claims.get("username");
        System.out.println("DEBUG: Token username = '" + tokenUsername + "', Requested username = '" + username + "'");
        System.out.println("DEBUG: All claims = " + claims.toString());
        
        if (tokenUsername == null) {
            System.out.println("DEBUG: Token username is null!");
            throw new AccessDeniedException("Token does not contain username claim");
        }
        
        if (!username.equalsIgnoreCase(tokenUsername)) {
            System.out.println("DEBUG: Username mismatch! Token: '" + tokenUsername + "', Requested: '" + username + "'");
            throw new AccessDeniedException("No access for requested entity - Token username: " + tokenUsername + ", Requested: " + username);
        }
        
        System.out.println("DEBUG: Authorization successful for user: " + username);

        return userRepository.findOneByUsername(username);
    }

}
