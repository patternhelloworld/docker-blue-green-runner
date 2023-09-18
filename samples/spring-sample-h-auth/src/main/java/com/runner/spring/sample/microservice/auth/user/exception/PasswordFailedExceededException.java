package com.runner.spring.sample.microservice.auth.user.exception;

import com.runner.spring.sample.exception.error.ErrorCode;
import lombok.Getter;

@Getter
public class PasswordFailedExceededException extends RuntimeException {

    private ErrorCode errorCode;

    public PasswordFailedExceededException() {
        this.errorCode = ErrorCode.PASSWORD_FAILED_EXCEEDED;
    }
}
