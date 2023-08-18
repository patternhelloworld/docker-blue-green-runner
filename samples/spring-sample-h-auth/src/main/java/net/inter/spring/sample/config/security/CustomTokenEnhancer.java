package net.inter.spring.sample.config.security;

import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
import net.inter.spring.sample.config.security.dao.CustomOauthClientDetailsRepository;
import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.config.security.entity.CustomOAuthClientDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.oauth2.common.DefaultOAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.TokenEnhancer;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;

@Component
public class CustomTokenEnhancer implements TokenEnhancer {

    @Autowired
    private UserRepository userRepository;

    // CSAP 기준 : 90 일 (7,776,000 초) / 테스트 용 : 30 초
    private final long passwordExpirationsSec = 7776000;


    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {

        final Map<String, Object> additionalInfo = new HashMap<>();

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new UsernameNotFoundException("Email : " + authentication.getName() + " not found"));

        additionalInfo.put("password_expiration_sec", passwordExpirationsSec);

        if(user.getPasswordChangedAt() == null){
            additionalInfo.put("password_expired", true);
            // 다음 초(sec) 전 부터 패스워드 유효 기간이 지났다.
            additionalInfo.put("password_invalid_for_the_previous", 0);
            additionalInfo.put("password_valid_for_the_next", 0);
        }else{
            long diffSecFromPasswordChangedAtToNow = Duration.between(user.getPasswordChangedAt(), LocalDateTime.now()).getSeconds();

            if (diffSecFromPasswordChangedAtToNow < passwordExpirationsSec) {
                additionalInfo.put("password_expired", false);
                // 앞으로 다음 초(sec) 동안 패스워드 유효 기간이 남아 있다.
                additionalInfo.put("password_valid_for_the_next", passwordExpirationsSec - diffSecFromPasswordChangedAtToNow);
                additionalInfo.put("password_invalid_for_the_previous", 0);
            }else{
                additionalInfo.put("password_expired", true);
                // 다음 초(sec) 전 부터 패스워드 유효 기간이 지났다.
                additionalInfo.put("password_invalid_for_the_previous", diffSecFromPasswordChangedAtToNow - passwordExpirationsSec);
                additionalInfo.put("password_valid_for_the_next", 0);


                //((DefaultOAuth2AccessToken) accessToken).setExpiration(new Date());
            }
        }

        ((DefaultOAuth2AccessToken) accessToken).setAdditionalInformation(additionalInfo);
        return accessToken;
    }
}