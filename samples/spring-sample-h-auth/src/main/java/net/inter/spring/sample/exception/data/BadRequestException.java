package net.inter.spring.sample.exception.data;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class BadRequestException extends RuntimeException {
    public final static String DEFAULT_MESSAGE = "유효하지 않은 값입니다.";
    private String field;

    public BadRequestException(String field) {
        super(DEFAULT_MESSAGE);
        this.field = field;
    }

    public BadRequestException(String message, String field) {
        super(message);
        this.field = field;
    }

    public String getField() {
        return field;
    }

    public void setField(String field) {
        this.field = field;
    }
}
