package com.runner.spring.sample.microservice.auth.base.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

@RestController
public class BaseApi {

    @Value("${spring.profiles.active}")
    private String activeProfile;

/*    @Autowired
    private ServletWebServerApplicationContext server;*/

    @GetMapping("/systemProfile")
    public String getProfile () {
        return activeProfile;
    }

/*
    @GetMapping("/localPort")
    public int getPort () {
        return server.getWebServer().getPort();
    }
*/

}
