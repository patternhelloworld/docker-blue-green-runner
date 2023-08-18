package net.inter.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.INTERNAL_SERVER_ERROR)
public class NotCreatedException extends RuntimeException{
	public NotCreatedException(String message){
		super(message);
	}
	public NotCreatedException(String message, Throwable cause) {
		super(message, cause);
	}
}
