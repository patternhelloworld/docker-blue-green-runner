package net.inter.spring.sample.util.auth;


import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;

import java.util.Set;

public interface MockAuth {

    /**
     * Mock @AuthenticationPrincipal
     */
    AccessTokenUserInfo mockAuthenticationPrincipal(User user);

    /**
     * Mock User
     */
    User mockUserObject(String dynamicRoles) throws Exception;

    /**
     * Mock AccessToken
     */
    String mockAccessToken(String clientName, String clientPassword, String username, String password) throws Exception;

    /**
     * Mock AccessToken on entity (select from DB)
     */
    String mockAccessTokenOnPersistence(String authUrl, String clientName, String clientPassword, String username, String password) throws Exception;
}
