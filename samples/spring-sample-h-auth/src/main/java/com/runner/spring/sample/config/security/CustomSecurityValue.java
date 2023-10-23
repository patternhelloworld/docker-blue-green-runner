package com.runner.spring.sample.config.security;

public enum CustomSecurityValue {

    loginMaxRetry(5);

    private final int value;

    public int getValue() {
        return value;
    }

    CustomSecurityValue(int value) {
        this.value = value;
    }
}

