package com.runner.spring.sample.microservice.auth.user.exception;

import com.runner.spring.sample.microservice.auth.user.entity.Email;
import lombok.Getter;

@Getter
public class AccountNotFoundException extends RuntimeException {

    private long id;
    private Email email;

    public AccountNotFoundException(long id) {
        this.id = id;
    }

    public AccountNotFoundException(Email email) {
        this.email = email;
    }

}
