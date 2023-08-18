package net.inter.spring.sample.config.security.api;

import net.inter.spring.sample.config.filter.UserPersistenceCheckFilter;
import net.inter.spring.sample.config.security.ResourceAuthFailureHandler;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableResourceServer;
import org.springframework.security.oauth2.config.annotation.web.configuration.ResourceServerConfigurerAdapter;
import org.springframework.security.oauth2.config.annotation.web.configurers.ResourceServerSecurityConfigurer;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableResourceServer
public class ResourceServer extends ResourceServerConfigurerAdapter {

    private static final String SAMPLEWAVE_RESOURCE_ID = "sample_h_resource";

    @Autowired
    private TokenStore tokenStore;

    @Override
    public void configure(ResourceServerSecurityConfigurer resources) {
        ResourceAuthFailureHandler resourceAuthFailureHandler = new ResourceAuthFailureHandler();
        resources.tokenStore(tokenStore).resourceId(SAMPLEWAVE_RESOURCE_ID).authenticationEntryPoint(resourceAuthFailureHandler)
                .accessDeniedHandler(resourceAuthFailureHandler);

    }

    @Autowired
    @Qualifier("authenticationManagerBean")
    private AuthenticationManager authenticationManager;

    @Autowired
    private ApplicationContext appContext;


    @Override
    public void configure(HttpSecurity http) throws Exception {
        http
                // 만약 이를 적용하지 않는다면 해당 사용자가 다시 로그인 할 때 까지 관리자가 수정한 권한이 적용되지 않는다.
                .addFilterBefore(new UserPersistenceCheckFilter(authenticationManager, appContext), UsernamePasswordAuthenticationFilter.class).authorizeRequests()
                .antMatchers(HttpMethod.OPTIONS).permitAll()
                // 시큐리티 처리에 HttpServletRequest를 이용한다는 것을 의미합니다.
                .antMatchers("/users/updateResetToken").permitAll()
                .antMatchers("/users/updateResetTokenTime").permitAll()
                .antMatchers("/**/admin/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN')")
                .antMatchers(HttpMethod.OPTIONS, "/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('WORKSPACE_READ') or hasAuthority('WORKSPACE_WRITE')")
                .antMatchers(HttpMethod.GET, "/**/workspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('WORKSPACE_READ')")
                .antMatchers(HttpMethod.POST, "/**/workspaces/**", "/**/organizations/invitationLink/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('WORKSPACE_WRITE') or hasAuthority('REGISTERED_ADMIN')")
                .antMatchers(HttpMethod.PUT, "/**/workspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('WORKSPACE_WRITE')")
                .antMatchers(HttpMethod.PATCH, "/**/workspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('WORKSPACE_WRITE')")
                .antMatchers(HttpMethod.DELETE, "/**/workspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('WORKSPACE_WRITE')")
                .antMatchers(HttpMethod.GET, "/**/binders/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_READ')")
                .antMatchers(HttpMethod.POST, "/**/binders/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_WRITE')")
                .antMatchers(HttpMethod.PUT, "/**/binders/batch").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN')")
                .antMatchers(HttpMethod.PUT, "/**/binders/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_WRITE')")
                .antMatchers(HttpMethod.PATCH, "/**/binders/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_WRITE')")
                .antMatchers(HttpMethod.DELETE, "/**/binders/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_WRITE')")
                .antMatchers(HttpMethod.PUT, "**/myInformation/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN') or hasAuthority('BINDER_WRITE')")
                .antMatchers(HttpMethod.POST, "/**/userWorkspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN')")
                .antMatchers(HttpMethod.PUT, "/**/userWorkspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN')")
                .antMatchers(HttpMethod.DELETE, "/**/userWorkspaces/**").access("hasAuthority('AKUO_ADMIN') or hasAuthority('REGISTERED_ADMIN')");

        //.anyRequest().fullyAuthenticated();
    }

}
