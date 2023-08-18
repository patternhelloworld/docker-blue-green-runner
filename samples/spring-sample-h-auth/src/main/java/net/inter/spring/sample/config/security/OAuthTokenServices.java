package net.inter.spring.sample.config.security;

import net.inter.spring.sample.config.security.entity.OauthRemovedAccessToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.DefaultTokenServices;

import java.util.LinkedHashMap;
import java.util.Objects;

public class OAuthTokenServices extends DefaultTokenServices {

    @Value("${oauth2.samplewave.pcApp.clientId}")
    private String pcAppClientId;


    @Override
    public OAuth2AccessToken createAccessToken(OAuth2Authentication authentication) throws AuthenticationException {

        OAuth2AccessToken token = super.getAccessToken(authentication);

        LinkedHashMap<String, String> details = (LinkedHashMap<String, String>) authentication.getUserAuthentication().getDetails();

        if (!Objects.isNull(token) && !token.isExpired()) {


            super.revokeToken(token.getValue());
        }

        return super.createAccessToken(authentication);

    }
}
