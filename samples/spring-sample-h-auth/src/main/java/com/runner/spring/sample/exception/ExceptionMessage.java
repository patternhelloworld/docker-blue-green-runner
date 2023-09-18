package com.runner.spring.sample.exception;

public enum ExceptionMessage implements ExceptionMessageInterface {

    NO_SUCH_ALGORITHM("no_such_algorithm"), //
    UNSUPPORTED_ENCODINGE("unsupported_encodinge"), //
    LOADING_MAIL_TEMPLATE_FAILURE("loading_mail_template_failure"); //

    private String message;

    @Override
    public String getMessage() {
        return message;
    }

    ExceptionMessage(String message) {
        this.message = message;
    }

}
