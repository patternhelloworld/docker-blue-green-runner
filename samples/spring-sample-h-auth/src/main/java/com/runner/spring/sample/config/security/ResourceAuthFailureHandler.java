package com.runner.spring.sample.config.security;

import com.runner.spring.sample.config.security.dao.OauthRemovedAccessTokenRepository;
import com.runner.spring.sample.config.security.entity.OauthRemovedAccessToken;
import org.codehaus.jackson.map.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.web.servlet.HandlerExceptionResolver;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

public class ResourceAuthFailureHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

    @Autowired
    @Qualifier("handlerExceptionResolver")
    private HandlerExceptionResolver resolver;

    @Autowired
    private OauthRemovedAccessTokenRepository oauthRemovedAccessTokenRepository;

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException e) throws IOException, ServletException {

        // oauth_removed_access_token 은 access_token 테이블에서 기간 만료의 경우를 제외한 (예. 다른 기기에서 로그인) 경우를 통해 무효화 된
        // 토큰들을 저장하고, 해당 테이블에 저장 된 무효화 된 원인을 찾아서 사용자에게 리턴한다.
        // oauth_removed_access_token 은 access_token 이 암호화 되지 않고 테이블에 저장되나, 이미 만료된 토큰이기 때문에 보안에 문제는 없을 것으로 보인다.
        // oauth_removed_access_token 의 가비지 값이 발생 한다면 Spring Security 의 남은 Access Token 유효 기간 (app.oauth2.front.accessTokenValiditySeconds) 에 created_at 컬럼을 더한 값들을 주기적으로 지워줄 필요가 있다.
        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.contains("Bearer")) {
            String tokenValue = authorization.replace("Bearer", "").trim();
            OauthRemovedAccessToken oauthRemovedAccessToken = Optional.of(oauthRemovedAccessTokenRepository.findById(tokenValue)).get().orElse(null);
            if(oauthRemovedAccessToken != null){

                oauthRemovedAccessTokenRepository.delete(oauthRemovedAccessToken);

                Map<String, Object> errorDetails = new HashMap<>();

                response.setStatus(HttpStatus.UNAUTHORIZED.value());

                errorDetails.put("timestamp", new Timestamp(System.currentTimeMillis()));
                errorDetails.put("details", "");
                errorDetails.put("message", "error=\\\"expired_token\\\", error_description=\\\"expired access token\\");
                errorDetails.put("userMessage", AccessTokenRemovedReason.ANOTHER_LOGIN.getMessage() + "(로그인 시각 : " + oauthRemovedAccessToken.getCreatedAt() + ")");

                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.setCharacterEncoding("utf-8");

                ObjectMapper objectMapper = new ObjectMapper();

                objectMapper.writeValue(response.getWriter(), errorDetails);

            }
        }

        resolver.resolveException(request, response, null, e);
    }

    @Override
    public void handle(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, AccessDeniedException e) throws IOException, ServletException {
        resolver.resolveException(httpServletRequest, httpServletResponse, null, e);
    }

}

