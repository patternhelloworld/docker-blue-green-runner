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

            if (!passwordEncoder.matches(password, user.getPassword())) {

                userService.handleFailCnt(user.getUsername());
                throw new BadCredentialsException("Wrong password.");

            }

            userService.resetFailCnt(user.getUsername());

            return new UsernamePasswordAuthenticationToken(user, password, user.getAuthorities());
        }
    }

    @Override
    public boolean supports(Class<? extends Object> authentication) {
        return (UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication));
    }

}
