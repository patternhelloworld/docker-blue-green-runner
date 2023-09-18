package com.runner.spring.sample.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CredentialChecker {
    private static final String emailRegEx =
            "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$";
    private static final Pattern emailPattern = Pattern.compile(emailRegEx);

    public static boolean isValidEmail(String email) {
        Matcher matcher = emailPattern.matcher(email);
        return matcher.find();
    }
}
