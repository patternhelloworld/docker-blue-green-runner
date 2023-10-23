package com.runner.spring.sample.config.security.api;


import com.runner.spring.sample.microservice.auth.user.dao.UserService;
import com.runner.spring.sample.config.security.OAuthTokenServices;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.env.Environment;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.config.annotation.configurers.ClientDetailsServiceConfigurer;
import org.springframework.security.oauth2.config.annotation.web.configuration.AuthorizationServerConfigurerAdapter;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableAuthorizationServer;
import org.springframework.security.oauth2.config.annotation.web.configurers.AuthorizationServerEndpointsConfigurer;
import org.springframework.security.oauth2.config.annotation.web.configurers.AuthorizationServerSecurityConfigurer;
import org.springframework.security.oauth2.provider.error.OAuth2AccessDeniedHandler;
import org.springframework.security.oauth2.provider.token.DefaultTokenServices;

import org.springframework.security.oauth2.provider.token.TokenStore;

import javax.annotation.Resource;

@Configuration
@EnableAuthorizationServer
public class AuthorizationServer extends AuthorizationServerConfigurerAdapter {

    @Autowired
    private TokenStore tokenStore;

    @Autowired
    DefaultTokenServices tokenServices;

    @Autowired
    @Qualifier("authenticationManagerBean")
    private AuthenticationManager authenticationManager;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private UserService userService;

    @Resource
    private Environment env;

    @Bean
    public OAuth2AccessDeniedHandler oauthAccessDeniedHandler() {
        return new OAuth2AccessDeniedHandler();
    }

    @Override
    public void configure(AuthorizationServerSecurityConfigurer oauthServer) {
        oauthServer.tokenKeyAccess("permitAll()").checkTokenAccess("isAuthenticated()").passwordEncoder(passwordEncoder);
    }

    @Bean
    @Primary
    public DefaultTokenServices tokenServices() {
        OAuthTokenServices tokenService = new OAuthTokenServices();
        tokenService.setTokenStore(tokenStore);
        tokenService.setSupportRefreshToken(true);
        tokenService.setAccessTokenValiditySeconds(env.getRequiredProperty("app.oauth2.front.accessTokenValiditySeconds", Integer.class));
        tokenService.setRefreshTokenValiditySeconds(env.getRequiredProperty("app.oauth2.front.refreshTokenValiditySeconds", Integer.class));

        return tokenService;
    }

    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
        endpoints.tokenServices(tokenServices).authenticationManager(authenticationManager)
                .userDetailsService(userService).pathMapping("/oauth/token", "/oauth/token-endpoint");;
    }

    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {

        clients.inMemory()
                //.withClientDetails(clientDetailsService)
                .withClient(env.getRequiredProperty("app.oauth2.front.clientId"))
                .secret(passwordEncoder.encode(env.getRequiredProperty("app.oauth2.front.clientSecret")))
                // 이러한 ROLE 들이 없으면 로그인이 불가하다.
                .authorities("ROLE_USER")
                .authorizedGrantTypes("authorization_code", "password", "refresh_token")
                //.authorizedGrantTypes("password")
                .scopes("read", "write")
                .accessTokenValiditySeconds(env.getRequiredProperty("app.oauth2.front.accessTokenValiditySeconds", Integer.class))
                .refreshTokenValiditySeconds(env.getRequiredProperty("app.oauth2.front.refreshTokenValiditySeconds", Integer.class))
                // autoapprove: 권한코드 방식 같은 형태로 Access Token을 발급받을 때에는 사용자에게 scope 범위를 허가받는 화면이 나옵니다.
                // 이 화면 자체가 나오지 않게 설정하는 값입니다. true하면 아래 화면이 나오지 않습니다.
                // implicit 방식은 이 프로젝트에서 사용하지 않으므로 사실상 의미 없음
                .autoApprove(true)
                .and()
                .withClient(env.getRequiredProperty("app.oauth2.pcApp.clientId"))
                .secret(passwordEncoder.encode(env.getRequiredProperty("app.oauth2.pcApp.clientSecret")))
                // 이러한 ROLE 들이 없으면 로그인이 불가하다.
                .authorities("ROLE_USER")
                .authorizedGrantTypes("authorization_code", "password", "refresh_token")
                .scopes("read", "write")
                .accessTokenValiditySeconds(env.getRequiredProperty("app.oauth2.pcApp.accessTokenValiditySeconds", Integer.class))
                .refreshTokenValiditySeconds(env.getRequiredProperty("app.oauth2.pcApp.refreshTokenValiditySeconds", Integer.class))
                // autoapprove: 권한코드 방식 같은 형태로 Access Token을 발급받을 때에는 사용자에게 scope 범위를 허가받는 화면이 나옵니다.
                // 이 화면 자체가 나오지 않게 설정하는 값입니다. true하면 아래 화면이 나오지 않습니다.
                // implicit 방식은 이 프로젝트에서 사용하지 않으므로 사실상 의미 없음
                .autoApprove(true);

    }
}