package net.inter.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.CONFLICT)
public class NoDynamicTableFoundException extends RuntimeException{
	public NoDynamicTableFoundException(String message){
		super(message);
    }
	public NoDynamicTableFoundException(String message, Throwable cause) {
		super(message, cause);
	}
}
