package net.inter.spring.sample.microservice.auth.user.exception;

import lombok.Getter;
import net.inter.spring.sample.microservice.auth.user.entity.Email;

@Getter
public class EmailDuplicationException extends RuntimeException {

    private Email email;
    private String field;

  public EmailDuplicationException(Email email) {
        this.field = "email";
        this.email = email;
    }
}
