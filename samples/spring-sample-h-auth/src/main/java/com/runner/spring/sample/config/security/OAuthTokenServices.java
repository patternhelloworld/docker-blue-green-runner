package com.runner.spring.sample.config.security;

import com.runner.spring.sample.config.security.dao.OauthRemovedAccessTokenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.DefaultTokenServices;

import java.util.LinkedHashMap;
import java.util.Objects;


public class OAuthTokenServices extends DefaultTokenServices {

    @Autowired
    private OauthRemovedAccessTokenRepository oauthRemovedAccessTokenRepository;

    @Override
    public OAuth2AccessToken createAccessToken(OAuth2Authentication authentication) throws AuthenticationException {

        OAuth2AccessToken token = super.getAccessToken(authentication);

        LinkedHashMap<String, String> details = (LinkedHashMap<String, String>) authentication.getUserAuthentication().getDetails();

        if (!Objects.isNull(token) && !token.isExpired()) {

            // 기존에 해당 사용자로 로그인 한 토큰이 oauth_access_token 테이블에 있다면...
            // 하단 1), 2), 3)  @Transactional 처리 불필요 (부모 클래스 존재)
/*
            OauthRemovedAccessToken oauthRemovedAccessToken = new OauthRemovedAccessToken();
            oauthRemovedAccessToken.setAccessToken(token.getValue());
            oauthRemovedAccessToken.setReason(AccessTokenRemovedReason.ANOTHER_LOGIN.getDbValue());
            oauthRemovedAccessToken.setUserName(details.get("username"));

            // 1) oauth_removed_access_token 테이블에 해당 값을 저장하고
            oauthRemovedAccessTokenRepository.save(oauthRemovedAccessToken);
            // 2) oauth_access_token 테이블에서 해당 토큰을 삭제 시킨다
            super.revokeToken(token.getValue());*/
            return token;
        }else{
            return super.createAccessToken(authentication);
        }

        // 3) 기존에 해당 사용자로 로그인 한 토큰이 있던 없던 항상 신규 토큰을 생성한다.
        //return super.createAccessToken(authentication);

    }
}
