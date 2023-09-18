package com.runner.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.CONFLICT)
public class PreconditionFailedException extends RuntimeException{
	public PreconditionFailedException(String message){
		super(message);
	}
	public PreconditionFailedException(String message, Throwable cause) {
		super(message, cause);
	}
}
