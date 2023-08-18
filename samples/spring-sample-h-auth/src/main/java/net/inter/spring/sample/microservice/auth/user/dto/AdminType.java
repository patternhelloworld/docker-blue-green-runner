package net.inter.spring.sample.microservice.auth.user.dto;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.auth.user.entity.User;

@Getter
@Setter
public class AdminType {

    private Boolean isSuperAdmin;
    private Boolean isAdmin;
    private User user;

}
