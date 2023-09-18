package com.runner.spring.sample.util.auth;

import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;

public interface MockAuth {

    /**
     * Mock @AuthenticationPrincipal
     */
    AccessTokenUserInfo mockAuthenticationPrincipal(User user);

    /**
     * Mock User
     */
    User mockUserObject() throws Exception;

    /**
     * Mock AccessToken
     */
    String mockAccessToken(String clientName, String clientPassword, String username, String password) throws Exception;

    /**
     * Mock AccessToken on entity (select from DB)
     */
    String mockAccessTokenOnPersistence(String authUrl, String clientName, String clientPassword, String username, String password) throws Exception;
}
