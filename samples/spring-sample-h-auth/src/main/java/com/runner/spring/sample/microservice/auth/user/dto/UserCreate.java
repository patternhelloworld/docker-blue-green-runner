package com.runner.spring.sample.microservice.auth.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserCreate {
    public String email;
    public String name;
}
