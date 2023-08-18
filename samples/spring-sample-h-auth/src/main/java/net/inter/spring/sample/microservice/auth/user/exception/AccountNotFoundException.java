package net.inter.spring.sample.microservice.auth.user.exception;

import lombok.Getter;
import net.inter.spring.sample.microservice.auth.user.entity.Email;

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
