package com.runner.spring.sample.microservice.auth.user.dto;

import com.runner.spring.sample.microservice.auth.user.entity.User;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AdminType {

    private Boolean isSuperAdmin;
    private Boolean isAdmin;
    private User user;

}
