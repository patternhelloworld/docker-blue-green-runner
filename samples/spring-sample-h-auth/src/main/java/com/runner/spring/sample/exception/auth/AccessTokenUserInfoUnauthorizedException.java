package com.runner.spring.sample.exception.auth;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/*
        403은 미인증
        비인증: 非, Not
        비인증은 아니다의 뜻이 강하다. 즉, 인증이 안된 상태다.
        미인증: 未, Not enough
        미인증은 부족하다의 뜻이 강하다. 즉, 권한이 부족한 상태다*/

@ResponseStatus(value = HttpStatus.FORBIDDEN)
public class AccessTokenUserInfoUnauthorizedException extends RuntimeException {

    public AccessTokenUserInfoUnauthorizedException(String message) {
        super(message);
    }
}