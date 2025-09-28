package com.elgris.usersapi.api;

import org.springframework.web.bind.annotation.*;
import javax.servlet.http.HttpServletRequest;

@RestController
public class HealthController {

    @RequestMapping(value = "/health", method = RequestMethod.GET)
    public String health() {
        return "OK";
    }

    @RequestMapping(value = "/debug/{username}", method = RequestMethod.GET)
    public String debug(HttpServletRequest request, @PathVariable("username") String username) {
        Object requestAttribute = request.getAttribute("claims");
        if (requestAttribute == null) {
            return "No claims found";
        }
        return "Claims: " + requestAttribute.toString() + ", Requested username: " + username;
    }
}