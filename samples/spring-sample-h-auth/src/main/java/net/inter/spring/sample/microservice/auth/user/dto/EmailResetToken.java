package net.inter.spring.sample.microservice.auth.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EmailResetToken {

    private String email;
    private String resetToken;

}
