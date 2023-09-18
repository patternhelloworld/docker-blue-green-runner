package com.runner.spring.sample.exception.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.oauth2.common.exceptions.OAuth2Exception;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.FORBIDDEN)
public class ClientDisabledException extends OAuth2Exception{

	public int getHttpErrorCode() {
		return HttpStatus.FORBIDDEN.value();
	}

	public ClientDisabledException(String message){
    	super(message);
    }
	public ClientDisabledException(String message, Throwable cause) {
		super(message, cause);
	}
}
