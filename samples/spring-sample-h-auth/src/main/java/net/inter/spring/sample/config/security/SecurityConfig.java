package net.inter.spring.sample.config.security;



import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.security.oauth2.provider.token.store.JdbcTokenStore;
import org.springframework.security.web.authentication.rememberme.JdbcTokenRepositoryImpl;
import org.springframework.security.web.authentication.rememberme.PersistentTokenRepository;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import javax.sql.DataSource;


// 해당 클래스를 Configuration으로 등록한다.
@Configuration

// Web
// Spring Security를 활성화 시킵니다.
@EnableWebSecurity

// Api
// Controller에서 특정 페이지에 특정 권한이 있는 유저만 접근을 허용할 경우 @PreAuthorize 어노테이션을 사용하는데,
// 해당 어노테이션에 대한 설정을 활성화시키는 어노테이션입니다. (필수는 아닙니다.)
// @Secured 애노테이션을 사용하여 인가 처리를 하고 싶을때 사용하는 옵션이다.
// @prePostEnabled @PreAuthorize, @PostAuthorize 애노테이션을 사용하여 인가 처리를 하고 싶을때 사용하는 옵션이다.
// @RolesAllowed 애노테이션을 사용하여 인가 처리를 하고 싶을때 사용하는 옵션이다.
@EnableGlobalMethodSecurity(securedEnabled = true, prePostEnabled = true, jsr250Enabled = true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    @Qualifier("authDataSource")
    private DataSource dataSource;


    @Autowired
    private CustomAuthenticationProvider customAuthenticationProvider;


    // dataSource(DB)에 access token을 persist 시킨다.
    @Bean
    public TokenStore tokenStore() {
        return new JdbcTokenStore(dataSource);
    }

    // DB에 암호를 저장하는 시점과 로그인 시 해당 알고리즘을 사용
    // KISA 의 권고에 따라 Bcrypt 를 사용하지 않고 SHA-256 을 사용하기로 함
    @Bean
    public PasswordEncoder passwordEncoder() {
        //return new MultiplePasswordEncoder(IdForPasswordEncoder.bcrypt);
        return new BCryptPasswordEncoder();
    }

    // AuthenticationManagerBuilder : DB를 연동
    @Override
    public void configure(AuthenticationManagerBuilder auth) throws Exception {

        auth.authenticationProvider(customAuthenticationProvider);
    }

    // AuthorizationServer.java 에서 사용
    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        configuration.addAllowedOrigin("*");
        configuration.addAllowedHeader("*");
        configuration.addAllowedMethod("*");
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }



/*
    @Bean
    public AuthenticationProvider daoAuthenticationProvider() {
        DaoAuthenticationProvider impl = new DaoAuthenticationProvider();
        impl.setUserDetailsService(userService);

        Map<String, PasswordEncoder> encoders = new HashMap<>();
        encoders.put("SHA-256",
                new org.springframework.security.crypto.password.MessageDigestPasswordEncoder("SHA-256"));

        impl.setPasswordEncoder(new DelegatingPasswordEncoder("SHA-256", encoders));
        impl.setHideUserNotFoundExceptions(false) ;
        return impl ;
    }
*/


    @Autowired
    AuthFailureHandler authFailureHandler;


    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .headers()
                //.frameOptions().sameOrigin()
                .and()
                .authorizeRequests()
                .antMatchers(HttpMethod.OPTIONS, "/oauth/token").permitAll()
                .antMatchers("/resources/**", "/webjars/**","/assets/**","/oauth/token").permitAll()
                .anyRequest().authenticated()
                .and()
                //.oauth2Login().failureHandler(authFailureHandler).and()
                //http.formLogin()은 form 태그 기반의 로그인을 지원하겠다는 설정입니다.
                //- 이를 이용하면 별도의 로그인 페이지를 제작하지 않아도 됩니다.
                .formLogin()
                .authenticationDetailsSource(new TOTPWebAuthenticationDetailsSource())
                .loginPage("/login")
                .usernameParameter("email")
                .defaultSuccessUrl("/home")
                .failureUrl("/login?error")
                .permitAll()
                .and()
                .logout()
                .logoutRequestMatcher(new AntPathRequestMatcher("/logout"))
                .logoutSuccessUrl("/login?logout")
                .deleteCookies("my-remember-me-cookie")
                .permitAll()
                .and()
                .rememberMe()
                //.key("my-secure-key")
                .rememberMeCookieName("my-remember-me-cookie")
                .tokenRepository(persistentTokenRepository())
                .tokenValiditySeconds(24 * 60 * 60);

    }

    PersistentTokenRepository persistentTokenRepository(){
        JdbcTokenRepositoryImpl tokenRepositoryImpl = new JdbcTokenRepositoryImpl();
        tokenRepositoryImpl.setDataSource(dataSource);
        return tokenRepositoryImpl;
    }




}