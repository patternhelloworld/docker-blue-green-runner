package net.inter.spring.sample.exception.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.common.exceptions.UnauthorizedClientException;
import org.springframework.web.bind.annotation.ResponseStatus;

// 인증 (authenticated) : 401
// 승인 (authorized) : 403
// 그러나 자바에서는 HttpStatus객체에서 HttpStatus.UNAUTHORIZED를 401로 사용하여 여기에 이와 같이 입력함
@ResponseStatus(value = HttpStatus.UNAUTHORIZED)
public class UnauthenticatedException extends RuntimeException {
    public UnauthenticatedException(String message) {
        super(message);
    }
}