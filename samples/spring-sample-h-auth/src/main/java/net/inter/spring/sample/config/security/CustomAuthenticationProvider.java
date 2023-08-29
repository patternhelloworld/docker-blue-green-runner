package net.inter.spring.sample.config.security;

import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import net.inter.spring.sample.microservice.auth.user.dao.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.io.Serializable;


@RequiredArgsConstructor
@Component("AuthenticationProvider")
public class CustomAuthenticationProvider implements AuthenticationProvider, Serializable {

    @Autowired
    private UserService userService;

    private PasswordEncoder passwordEncoder;

    @Autowired
    public CustomAuthenticationProvider(@Lazy PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @Value("${oauth2.samplewave.front.clientId}")
    private String WebClientId;

    @SneakyThrows
    public Authentication authenticate(Authentication authentication)
            throws AuthenticationException {

        String userClientId = SecurityContextHolder.getContext().getAuthentication().getName();

        String username = authentication.getName();
        String password = authentication.getCredentials().toString();

        org.springframework.security.core.userdetails.User user = (org.springframework.security.core.userdetails.User) userService.loadUserByUsername(username);

        if (user == null || !user.getUsername().equalsIgnoreCase(username)) {
            throw new BadCredentialsException("Username not found.");
        } else {
            // pc App client는 2차 인증을 하지 않는다. web client일 때 2차 인증을 하도록 한다.
/*            if (userClientId.equals(WebClientId)) {
                LinkedHashMap<String, String> detailsProperties = (LinkedHashMap<String, String>) authentication.getDetails();
                Integer verificationCode = null;
                String totpKeyString = AES256.decrypt(detailsProperties.get("totp-verification-code"));
                if (StringUtils.hasText(totpKeyString)) {
                    try {
                        verificationCode = Integer.valueOf(totpKeyString);
                    } catch (NumberFormatException e) {
                        verificationCode = null;
                    }
                }
                Boolean IsWrong2FA = userService.handleIsUsing2FA(username, verificationCode);
                if(IsWrong2FA){
                    userService.handleFailCnt(user.getUsername());
                    throw new BadCredentialsException("Wrong 2FA code.");
                }
            }*/

            if (!passwordEncoder.matches(password, user.getPassword())) {

                userService.handleFailCnt(user.getUsername());
                throw new BadCredentialsException("Wrong password.");

            }
            //로그인 성공 시 fail_cnt 를 0으로 리셋
            userService.resetFailCnt(user.getUsername());
            //authentication객체의 authenticated의 값을 setAuthenticated(true)로 해주기 위해 UsernamePasswordAuthenticationToken(user, password, Authorities)을 사용한다.
            return new UsernamePasswordAuthenticationToken(user, password, user.getAuthorities());
        }
    }

    @Override
    public boolean supports(Class<? extends Object> authentication) {
        return (UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication));
    }

}
