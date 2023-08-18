package net.inter.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.NOT_FOUND)
public class ResourceNotFoundException extends RuntimeException{
	public ResourceNotFoundException(String message){
		super(message);
	}
	public ResourceNotFoundException(String message, Throwable cause) {
		super(message, cause);
	}
}
