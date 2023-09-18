package com.runner.spring.sample.microservice.auth.user.exception;

import com.runner.spring.sample.microservice.auth.user.entity.Email;
import lombok.Getter;

@Getter
public class EmailDuplicationException extends RuntimeException {

    private Email email;
    private String field;

  public EmailDuplicationException(Email email) {
        this.field = "email";
        this.email = email;
    }
}
