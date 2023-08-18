package net.inter.spring.sample.exception.handler;


import net.inter.spring.sample.exception.CustomExceptionUtils;
import net.inter.spring.sample.exception.auth.AccessTokenUserInfoUnauthorizedException;
import net.inter.spring.sample.exception.auth.UnauthorizedException;
import net.inter.spring.sample.exception.auth.UserNoPasswordException;
import net.inter.spring.sample.exception.data.*;
import net.inter.spring.sample.exception.payload.SearchFilterException;
import net.inter.spring.sample.config.logger.dto.ErrorDetails;
import org.apache.commons.lang3.StringUtils;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.InsufficientAuthenticationException;
import org.springframework.security.oauth2.common.exceptions.InvalidGrantException;
import org.springframework.transaction.HeuristicCompletionException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.context.request.WebRequest;

import javax.naming.AuthenticationException;
import java.util.Date;

@Order(Ordered.HIGHEST_PRECEDENCE)
@ControllerAdvice
public class GlobalExceptionHandler {

    // https://sanghaklee.tistory.com/61

    // 1. auth

    @ExceptionHandler({AccessTokenUserInfoUnauthorizedException.class, UserNoPasswordException.class})
    public ResponseEntity<?> authException1(Exception ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), CustomExceptionUtils.getAllCauses(ex), request.getDescription(false),
                ex.getMessage(), ex.getStackTrace()[0].toString());
        return new ResponseEntity<>(errorDetails, HttpStatus.UNAUTHORIZED);
    }

    @ExceptionHandler({UnauthorizedException.class})
    public ResponseEntity<?> authException2(Exception ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage() != null ? ex.getMessage() : CustomExceptionUtils.getAllCauses(ex), request.getDescription(false),
                ex.getMessage() != null ? "권한이 없습니다." : ex.getMessage(), ex.getStackTrace()[0].toString());
        return new ResponseEntity<>(errorDetails, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler({InsufficientAuthenticationException.class, AuthenticationException.class, InvalidGrantException.class})
    public ResponseEntity<?> authException3(Exception ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), CustomExceptionUtils.getAllCauses(ex), request.getDescription(false),
                ex.getMessage(), ex.getStackTrace()[0].toString());
        return new ResponseEntity<>(errorDetails, HttpStatus.UNAUTHORIZED);
    }


    // 2. data

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<?> resourceNotFoundException(ResourceNotFoundException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                ex.getMessage(), CustomExceptionUtils.getAllStackTraces(ex),
                CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(NoDynamicTableFoundException.class)
    public ResponseEntity<?> noDynamicTableFoundException(NoDynamicTableFoundException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                "동적 테이블이 존재하지 않습니다.", CustomExceptionUtils.getAllStackTraces(ex),
                CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(NoUpdateTargetException.class)
    public ResponseEntity<?> noUpdateTargetException(NoUpdateTargetException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                ex.getMessage(), ex.getStackTrace()[0].toString());
        return new ResponseEntity<>(errorDetails, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(SearchFilterException.class)
    public ResponseEntity<?> searchFilterException(SearchFilterException ex, WebRequest request) {

        //logger.error(ex.getMessage());
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getCause().getMessage(), request.getDescription(false),
                ex.getMessage(), ex.getStackTrace()[0].toString());
        return new ResponseEntity<>(errorDetails, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(AlreadyExistsException.class)
    public ResponseEntity<?> alreadyExistsException(AlreadyExistsException ex, WebRequest request) {

        //logger.error(ex.getMessage());
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                ex.getMessage(), CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.CONFLICT);
    }

    @ExceptionHandler(NullPointerException.class)
    public ResponseEntity<?> nullPointerException(NullPointerException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                "null 값으로 처리에 문제가 발생하였습니다.", CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(NotCreatedException.class)
    public ResponseEntity<?> notCreatedException(NotCreatedException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                "내부 오류로 조직 ID가 생성에 실패하였습니다.", CustomExceptionUtils.getAllStackTraces(ex),
                CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.NOT_FOUND);
    }


    @ExceptionHandler(PreconditionFailedException.class)
    public ResponseEntity<?> preconditionFailedException(PreconditionFailedException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                ex.getMessage(), CustomExceptionUtils.getAllStackTraces(ex),
                CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.CONFLICT);
    }


    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> methodArgumentNotValidException(MethodArgumentNotValidException ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                ex.getBindingResult().getAllErrors().get(0).getDefaultMessage(), CustomExceptionUtils.getAllStackTraces(ex),
                CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    // JPA 오류
    @ExceptionHandler(HeuristicCompletionException.class)
    public ResponseEntity<?> heuristicCompletionException(HeuristicCompletionException ex, WebRequest request) {

        // JPA - Unique key 오류
        if (ex.getCause().getClass().equals(DataIntegrityViolationException.class)) {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                    "중복되는 값이 있습니다.", CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
            return new ResponseEntity<>(errorDetails, HttpStatus.CONFLICT);
        } else {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false),
                    "JPA 처리되지 않은 오류입니다.", CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
            return new ResponseEntity<>(errorDetails, HttpStatus.CONFLICT);
        }

    }

    // JPA - Unique key 오류
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<?> dataIntegrityViolationException(DataIntegrityViolationException ex, WebRequest request) {
        //DataIntegrityViolationException - 데이터의 삽입/수정이 무결성 제약 조건을 위반할 때 발생하는 예외이다.
        //logger.error(ex.getMessage());

        ErrorDetails errorDetails = new ErrorDetails(new Date(), "DataIntegrityViolationException: could not execute statement.", request.getDescription(false),
                "중복되는 값이 있습니다.", CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.CONFLICT);
    }


    // 3. unhandled
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> unhandledExceptionHandler(Exception ex, WebRequest request) {
        ErrorDetails errorDetails = new ErrorDetails(new Date(), ex.getMessage(), request.getDescription(false), "처리되지 않은 오류 입니다.",
                CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    @ExceptionHandler(value = BadRequestException.class)
    public @ResponseBody
    ResponseEntity<?> validationRuntimeExceptionHandler(WebRequest request, Exception ex) {
        ex.printStackTrace();
        BadRequestException badRequestException = (BadRequestException) ex;
        String middle = "이(가) ";
        String suffix = StringUtils.isEmpty(badRequestException.getMessage()) ? BadRequestException.DEFAULT_MESSAGE : badRequestException.getMessage();
        String message = StringUtils.isEmpty(badRequestException.getField()) ? BadRequestException.DEFAULT_MESSAGE : String.format("%s%s%s", badRequestException.getField(), middle, suffix);
        ErrorDetails errorDetails = new ErrorDetails(new Date(), message, request.getDescription(false), message,
                CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));
        return new ResponseEntity<>(errorDetails, HttpStatus.BAD_REQUEST);
    }

}
