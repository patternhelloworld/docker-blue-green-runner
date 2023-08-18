package net.inter.spring.sample.microservice.auth.user.exception;

import lombok.Getter;
import net.inter.spring.sample.exception.error.ErrorCode;

@Getter
public class PasswordFailedExceededException extends RuntimeException {

    private ErrorCode errorCode;

    public PasswordFailedExceededException() {
        this.errorCode = ErrorCode.PASSWORD_FAILED_EXCEEDED;
    }
}
