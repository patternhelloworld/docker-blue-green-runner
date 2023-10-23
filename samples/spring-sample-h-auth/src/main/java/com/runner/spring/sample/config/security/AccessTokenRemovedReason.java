package com.runner.spring.sample.config.security;

public enum AccessTokenRemovedReason {
    ANOTHER_LOGIN(1, "다른 기기로 부터 로그인이 되었습니다.");

    private final int dbValue;
    private final String message;

    private AccessTokenRemovedReason(int dbValue, String message) {
        this.dbValue = dbValue;
        this.message = message;
    }

    public int getDbValue() {
        return dbValue;
    }

    public String getMessage() {
        return message;
    }
}
