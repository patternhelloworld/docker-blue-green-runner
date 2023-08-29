package net.inter.spring.sample.config.filter;

import net.inter.spring.sample.microservice.auth.role.entity.Role;
import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
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
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class UserPersistenceCheckFilter extends BasicAuthenticationFilter {

    private final UserService userService;

    public UserPersistenceCheckFilter(AuthenticationManager authenticationManager, ApplicationContext ctx) {
        super(authenticationManager);
        this.userService = ctx.getBean(UserService.class);
    }


    // Important : SecurityContext 의 인증 정보를 DB (User, Organization, Role) 기준으로 맞춘다.
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if(auth != null && userService!=  null) {

            // 1. 현재 사용자 가져오기
            User user = userService.findByEmailWithOrganizationRole(auth.getName());

            // 2. 동기화 (권한)
            List<GrantedAuthority> updatedAuthorities = new ArrayList<>();
            for (Role role : user.getUserRoles().stream().map(userRole -> userRole.getRole()).collect(Collectors.toList())) {
                updatedAuthorities.add(new SimpleGrantedAuthority(role.getName()));
            }


            Authentication newAuth = new UsernamePasswordAuthenticationToken(auth.getPrincipal(), auth.getCredentials(), updatedAuthorities);

            // 3. 동기화 (id, organization_id)
            ((AccessTokenUserInfo) newAuth.getPrincipal()).setId(user.getId());
            ((AccessTokenUserInfo) newAuth.getPrincipal()).setOrganization(user.getOrganization());

            SecurityContextHolder.clearContext();
            SecurityContextHolder.getContext().setAuthentication(newAuth);
        }

        filterChain.doFilter(request, response);

    }
}
