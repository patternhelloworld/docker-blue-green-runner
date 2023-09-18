package com.runner.spring.sample.exception;

import com.runner.spring.sample.config.logger.LogConfig;
import com.runner.spring.sample.config.logger.dto.ErrorDetails;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CustomExceptionUtils {

    private static final Logger logger = LoggerFactory.getLogger(LogConfig.class);

    public static void createNonStoppableErrorMessage(String message) {

        logger.error("[NON-STOPPABLE ERROR] : ");

        try {
            new LogConfig().endpointBefore(true, "");
        } catch (Exception ex2) {
            logger.error(ex2.getMessage());
        } finally {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), message, "Without exception param " + " / Thread ID = " + Thread.currentThread().getId() + " / StackTrace",
                    message, "", "");

            logger.error(" / " + errorDetails.toString());
        }

    }

    public static void createNonStoppableErrorMessage(String message, Throwable ex) {

        logger.error("[NON-STOPPABLE ERROR] : ");

        try {
            new LogConfig().endpointBefore(true, "");
        } catch (Exception ex2) {
            logger.error(ex2.getMessage());
        } finally {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), message, "Witho exception param " + " / Thread ID = " + Thread.currentThread().getId() + " / StackTrace",
                    message, CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));

            logger.error(" / " + errorDetails.toString());
        }

    }

    public static String getAllCausesWithStartMessage(Throwable e, String causes) {
        if (e.getCause() == null) return causes;
        causes += e.getCause() + " / ";
        return getAllCausesWithStartMessage(e.getCause(), causes);
    }

    public static String getAllCauses(Throwable e) {
        String causes = "";
        return getAllCausesWithStartMessage(e, causes);
    }

    public static String getAllStackTraces(Throwable e) {
        return ExceptionUtils.getStackTrace(e);
    }

    /*
    *   message 예시
    *   // could not execute statement; SQL [n/a]; constraint [car.chassis_number]
        // could not execute statement; SQL [n/a]; constraint [null]
    * */
    public static Map<String, String> convertDataIntegrityExceptionMessageToObj(String message, String fieldUserMessage){
        Map<String, String> map = new HashMap<>();
        map.put(parseKeyFromDataIntegrityExceptionMessage(message), fieldUserMessage);
        return map;
    }

    public static String parseKeyFromDataIntegrityExceptionMessage(String message){
        Pattern pattern = Pattern.compile("constraint \\[([^\\u005D]+)\\]");
        Matcher matcher = pattern.matcher(message);

        if (matcher.find()) {
            return matcher.group(1).replaceAll("^[^\\.]+\\.", "");
        } else {
            return "";
        }
    }

    public static Map<String, String> extractMethodArgumentNotValidErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();

        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            errors.put(error.getField(), error.getDefaultMessage());
        }

        return errors;
    }
}
