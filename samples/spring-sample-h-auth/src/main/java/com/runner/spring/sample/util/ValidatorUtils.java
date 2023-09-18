package com.runner.spring.sample.util;

import org.springframework.stereotype.Component;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class ValidatorUtils {
    private static final int MIN_SIZE = 9;
    private static final int MAX_SIZE = 20;
    private static final String regexPassword = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[$@!%*#?&])[A-Za-z[0-9]$@!%*#?&]{" + MIN_SIZE
            + "," + MAX_SIZE + "}$";
    private static final String regexConsecutiveNumber = "([0-9])\\1";

    public boolean isValid(String password) {
        return password.matches(regexPassword) && !findConsecutiveNumber(password) && !findContinuousPwd(password) ;
    }

    private boolean findConsecutiveNumber(String password){
        Pattern pattern = Pattern.compile(regexConsecutiveNumber);
        Matcher matcher = pattern.matcher(password);
        return matcher.find();
    }

    public boolean findContinuousPwd(String pwd) {
        int o = 0;
        int d = 0;
        int p = 0;
        int n = 0;
        int limit = 3;

        for(int i=0; i<pwd.length(); i++) {
            char tempVal = pwd.charAt(i);
            if(i > 0 && (p = o - tempVal) > -2 && (n = p == d ? n + 1 :0) > limit -3) {
                return true;
            }
            d = p;
            o = tempVal;
        }
        return false;
    }
}
