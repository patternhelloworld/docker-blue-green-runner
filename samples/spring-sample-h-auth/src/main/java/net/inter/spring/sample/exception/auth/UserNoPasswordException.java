package net.inter.spring.sample.exception.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.UNAUTHORIZED)
public class UserNoPasswordException extends UsernameNotFoundException{
	public UserNoPasswordException(String message){
    	super(message);
    }
	public UserNoPasswordException(String message, Throwable cause) {
		super(message, cause);
	}
}
