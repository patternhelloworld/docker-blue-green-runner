package net.inter.spring.sample.config.filter;

import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.microservice.auth.user.dao.UserService;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;

import org.springframework.context.ApplicationContext;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class UserPersistenceCheckFilter extends BasicAuthenticationFilter {

    private UserService userService;

    public UserPersistenceCheckFilter(AuthenticationManager authenticationManager, ApplicationContext ctx) {
        super(authenticationManager);
        this.userService = ctx.getBean(UserService.class);
    }


    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if(auth != null && userService !=  null) {

            User user = userService.getUserEntityByEmail(auth.getName());

            Authentication newAuth = new UsernamePasswordAuthenticationToken(auth.getPrincipal(), auth.getCredentials());

            // 3. 동기화 (id, organization_id)
            ((AccessTokenUserInfo) newAuth.getPrincipal()).setId(user.getId());
            ((AccessTokenUserInfo) newAuth.getPrincipal()).setOrganization_id(user.getOrganization_id());

            SecurityContextHolder.clearContext();
            SecurityContextHolder.getContext().setAuthentication(newAuth);
        }

        filterChain.doFilter(request, response);

    }
}
