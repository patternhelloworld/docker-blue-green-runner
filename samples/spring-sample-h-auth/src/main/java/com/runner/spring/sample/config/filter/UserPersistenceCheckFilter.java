package com.runner.spring.sample.config.filter;

import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import com.runner.spring.sample.microservice.auth.role.entity.Role;
import com.runner.spring.sample.microservice.auth.user.dao.UserService;
import com.runner.spring.sample.microservice.auth.user.dto.UserDTO;
import com.runner.spring.sample.microservice.auth.user.entity.User;
import org.springframework.context.ApplicationContext;
import org.springframework.security.authentication.AuthenticationManager;
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
import java.util.stream.Collectors;

public class UserPersistenceCheckFilter extends BasicAuthenticationFilter {

    private final UserService userService;

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

        if(auth != null && userService!=  null) {


            User user = userService.findByEmailWithOrganizationRole(auth.getName());


            List<GrantedAuthority> updatedAuthorities = new ArrayList<>();
            for (Role role : user.getUserRoles().stream().map(userRole -> userRole.getRole()).collect(Collectors.toList())) {
                updatedAuthorities.add(new SimpleGrantedAuthority(role.getName()));
            }


            // 3. 동기화 (User 객체)
            // - 이미 발급 된 access_token 의 user 정보와, 현재 user 테이블의 user 정보는 다르기 때문에 (예를 들어, access_token 발급 시점의 email 이 test@test.com 인데, 그 후 이메일이 변경되어 test5@test.com 이라면 불일치 발생,
            // - 동기화가 필요한 속성들은 여기서 동기화 해주어야 한다. 단, Spring security 고유의 username 은 set 이 당연히 안된다.
            ((AccessTokenUserInfo) auth.getPrincipal()).setAccessTokenUser(new UserDTO.AccessTokenUser(user));

        }

        filterChain.doFilter(request, response);

    }
}
