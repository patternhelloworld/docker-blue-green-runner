package net.inter.spring.sample.microservice.auth.user.dto;


import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.auth.user.validator.Password;

import javax.validation.constraints.NotBlank;

@Getter
@Setter
public class PasswordReset {

    @Password
    private String password;
    @NotBlank
    private String resetToken;

    private String name;

    @javax.validation.constraints.Email
    private String email;

    private String organizationInvitationToken;

}