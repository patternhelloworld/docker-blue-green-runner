package net.inter.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.NOT_FOUND)
public class NoUpdateTargetException extends Exception{
	public NoUpdateTargetException(String message){

		super(message);
    }
	public NoUpdateTargetException(String message, Throwable cause) {
		super(message, cause);
	}
}
