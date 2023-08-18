package net.inter.spring.sample.microservice.auth.base.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

@RestController
public class BaseApi {

    @Value("${spring.profiles.active}")
    private String activeProfile;

    @GetMapping("/systemProfile")
    public String getProfile () {
        return activeProfile;
    }
    
}
