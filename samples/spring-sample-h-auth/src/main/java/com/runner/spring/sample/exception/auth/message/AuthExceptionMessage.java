package com.runner.spring.sample.exception.auth.message;

import com.runner.spring.sample.exception.ExceptionMessageInterface;

public enum AuthExceptionMessage implements ExceptionMessageInterface {

    USER_NO_PASSWORD("활성화 되지 않은 사용자 입니다.");

    private String message;

    @Override
    public String getMessage() {
        return message;
    }

    AuthExceptionMessage(String message) {
        this.message = message;
    }

}
