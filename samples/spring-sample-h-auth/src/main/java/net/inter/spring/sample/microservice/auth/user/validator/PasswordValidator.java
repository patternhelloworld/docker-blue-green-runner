package net.inter.spring.sample.microservice.auth.user.validator;

import org.springframework.stereotype.Component;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.text.MessageFormat;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class PasswordValidator implements ConstraintValidator<Password, String> {

    private static final int MIN_SIZE = 9;
    private static final int MAX_SIZE = 20;
    private static final String regexPassword = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[$@!%*#?&])[A-Za-z[0-9]$@!%*#?&]{" + MIN_SIZE
            + "," + MAX_SIZE + "}$";
    private static final String regexConsecutiveNumber = "([0-9])\\1";

    @Override
    public void initialize(Password constraintAnnotation) {
    }

    @Override
    public boolean isValid(String password, ConstraintValidatorContext context) {
        boolean isValidPassword = password.matches(regexPassword) && !findConsecutiveNumber(password);
        if (!isValidPassword) {
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(
                    MessageFormat.format("{0}자 이상의 {1}자 이하의 숫자, 영문자, 특수문자를 포함하고, 연속된 숫자가 아닌 비밀번호를 입력하십시오.", MIN_SIZE, MAX_SIZE))
                    .addConstraintViolation();
        }
        return isValidPassword;
    }

    private boolean findConsecutiveNumber(String password){
        Pattern pattern = Pattern.compile(regexConsecutiveNumber);
        Matcher matcher = pattern.matcher(password);
        return matcher.find();
    }
}