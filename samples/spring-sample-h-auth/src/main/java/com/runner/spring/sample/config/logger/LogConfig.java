package com.runner.spring.sample.config.logger;

import com.fasterxml.jackson.databind.ObjectMapper;


import com.runner.spring.sample.exception.handler.GlobalExceptionHandler;
import com.runner.spring.sample.config.logger.dto.ErrorDetails;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.*;
import org.aspectj.lang.reflect.CodeSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.Map;
import java.util.stream.Collectors;

/*
 *
 * */
@Aspect
@Component
public class LogConfig {

    private static final Logger logger = LoggerFactory.getLogger(LogConfig.class);


    public void endpointBefore(boolean isErrored, String payload) {

        String loggedText = " [Before - Thread] : " + Thread.currentThread().getId() + "\n";

        // 1. Request logging
        try {
            loggedText += requestLogging(payload);
        } catch (Exception ex) {
            isErrored = true;
            loggedText += "\n[Before - Error during the requestLogging] : " + ex.getMessage();
        }

        // 2. Auth
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null) {
                loggedText += "\n[Before - Auth] : " + auth.getName();
            } else {
                loggedText += "\n[Before - Auth] : " + "null";
            }
        } catch (Exception ex2) {
            isErrored = true;
            loggedText += "\n[Before - Error during the authGet] : " + ex2.getMessage();
        }

        if (isErrored) {
            logger.error(loggedText + "\n");
        } else {
            logger.trace(loggedText + "\n");
        }

    }

    private String getPayload(JoinPoint joinPoint) {

        try {
            CodeSignature signature = (CodeSignature) joinPoint.getSignature();
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < joinPoint.getArgs().length; i++) {
                String parameterName = signature.getParameterNames()[i];
                builder.append(parameterName);
                builder.append(": ");
                if (joinPoint.getArgs()[i] != null) {
                    builder.append(joinPoint.getArgs()[i].toString());
                }
                builder.append(", ");
            }
            return builder.toString();
        } catch (Exception ex) {
            logger.error(ex.getMessage() + "\n");
        }

        return "LoggingPayloadFailed";
    }


    // 표현식 설명 : com.runner.spring.sample.controller 패키지 및 하위 패키지(..)의 모든 메서드(*)
    @AfterReturning(pointcut = ("within(com.runner.spring.sample.controller..*)"),
            returning = "returnValue")
    public void endpointAfterReturning(JoinPoint p, Object returnValue) {

        boolean isErrored = false;
        String loggedText = " [After - Returning Thread] : " + Thread.currentThread().getId() + "\n";

        // 3. Response logging
        try {
            ObjectMapper mapper = new ObjectMapper();

            if (returnValue.getClass().equals(ResponseEntity.class)) {
                MediaType mediaType = ((ResponseEntity) returnValue).getHeaders().getContentType();

                if (mediaType != null && (mediaType.getType().equals("image") || mediaType.equals(MediaType.APPLICATION_OCTET_STREAM))) {
                    loggedText += "\n[After - Response] \n" + "Image binary";
                } else {
                    loggedText += "\n[After - Response] \n" + mapper.writeValueAsString(returnValue);
                }
            } else {
                loggedText += "\n[After - Response] \n" + mapper.writeValueAsString(returnValue);
            }

        } catch (Exception ex3) {
            isErrored = true;
            loggedText += "\n[After - Error during the responseLogging] : " + ex3.getMessage();
        }

        // 5. 발생한 객체
        try {
            loggedText += "\n[After - Location] : " + p.getTarget().getClass().getSimpleName() + " " + p.getSignature().getName();
        } catch (Exception ex5) {
            isErrored = true;
            loggedText += "\n[After - Error during the finalStage] : " + ex5.getMessage();
        }

        endpointBefore(isErrored, getPayload(p));

        if (isErrored) {
            logger.error(loggedText + "\n");
        } else {
            logger.trace(loggedText + "\n");
        }


    }


    @AfterReturning(pointcut = ("within(com.runner.spring.sample.exception.handler..*)"),
            returning = "returnValue")
    public void endpointAfterExceptionReturning(JoinPoint p, Object returnValue) {

        String loggedText = " [After Throwing Thread] : " + Thread.currentThread().getId() + "\n";

        // 4. Error logging
        try {
            if (p.getTarget().getClass().equals(GlobalExceptionHandler.class)) {

                ErrorDetails errorDetails = (ErrorDetails) ((ResponseEntity) returnValue).getBody();
                loggedText += String.format("\n[Error details]\n message : %s, \n userMessage : %s, \n cause : %s, \n stackTrace : %s",
                        errorDetails != null ? errorDetails.getMessage() : "No error detail message",
                        errorDetails != null ? errorDetails.getUserMessage() : "No error detail auth message",
                        errorDetails != null ? errorDetails.getCause() : "No error detail cause",
                        errorDetails != null ? errorDetails.getStackTrace() : "No error detail stack trace");
            }
        } catch (Exception ex4) {

            loggedText += "\n[Error during the errorLogging] : " + ex4.getMessage();
        }

        // 5. 발생한 객체
        try {
            loggedText += "\n[Location] : " + p.getTarget().getClass().getSimpleName() + " " + p.getSignature().getName();
        } catch (Exception ex5) {
            loggedText += "\n[Error during the finalStage] : " + ex5.getMessage();
        }

        endpointBefore(true, getPayload(p));

        logger.error(loggedText + "\n");
    }


    private String paramMapToString(Map<String, String[]> paramMap) {
        return paramMap.entrySet().stream()
                .map(entry -> !checkIfNoLogginParam(entry.getKey()) ? String.format("%s -> (%s)",
                        entry.getKey(), String.join(",", entry.getValue())) : "")
                .collect(Collectors.joining(", "));
    }

    private static final String[] NO_LOGGING_PARAMS = {"image", "aocrImage", "aocrImageZip"};

    private boolean checkIfNoLogginParam(String key) {
        return Arrays.asList(NO_LOGGING_PARAMS).contains(key);
    }


    private String requestLogging(String payload) {
        HttpServletRequest request = // 5
                ((ServletRequestAttributes) RequestContextHolder.currentRequestAttributes()).getRequest();

        Map<String, String[]> paramMap = request.getParameterMap();
        String params = "";
        if (!paramMap.isEmpty()) {
            params = " [" + paramMapToString(paramMap) + "]";
        }

        //  JsonUtils.readJSONStringFromRequestBody : request.getReader()에서 InputStream을 생성하는데, 이걸 tomcat에서 한번만 사용할 수 있도록 막아두어서, 한번 read한 body값은 다시 읽을 수 없게 되어 있다.
        return String.format("\n[Request] \n %s, %s, %s, %s, < %s", request.getMethod(), request.getRequestURI(),
                params, payload, request.getRemoteHost());
    }


}