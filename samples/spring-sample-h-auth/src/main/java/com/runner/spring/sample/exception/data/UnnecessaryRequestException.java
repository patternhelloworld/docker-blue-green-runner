package com.runner.spring.sample.exception.data;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.INTERNAL_SERVER_ERROR)
public class UnnecessaryRequestException extends RuntimeException{
    public UnnecessaryRequestException(String message){
        super(message);
    }
    public UnnecessaryRequestException(String message, Throwable cause) {
        super(message, cause);
    }
}
