package com.runner.spring.sample.util.auth;

import com.runner.spring.sample.microservice.auth.role.entity.Role;
import com.runner.spring.sample.microservice.auth.user.dto.UserDTO;
import com.runner.spring.sample.microservice.auth.user.entity.Password;
import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import com.runner.spring.sample.microservice.auth.user.entity.UserRole;
import org.junit.Assert;
import org.springframework.boot.json.JacksonJsonParser;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.util.*;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public abstract class AbstractMockAuth implements MockAuth {

    public static final Long MOCKED_USER_ACCESS_TOKEN_ORGANIZATION_ID = 5L;
    public static final Long MOCKED_USER_ACCESS_TOKEN_USER_ID = 1L;

    @Override
    public AccessTokenUserInfo mockAuthenticationPrincipal(User user) {

        String username = user.getEmail();
        String password = user.getPassword().getValue();

        boolean enabled = true;
        boolean accountNonExpired = true;
        boolean credentialsNonExpired = true;
        boolean accountNonLocked = true;

        AccessTokenUserInfo authUser = new AccessTokenUserInfo(username, password, enabled, accountNonExpired, credentialsNonExpired,
                accountNonLocked, getAuthorities(user));

        authUser.setAccessTokenUser(new UserDTO.AccessTokenUser(user));

        return authUser;
    }
    private static Collection<? extends GrantedAuthority> getAuthorities(User user) {
        if(user.getUserRoles() == null){
            return new ArrayList<>();
        }

        String[] userRoles = user.getUserRoles().stream().map((userRole) -> userRole.getRole().getName()).toArray(String[]::new);
        Collection<GrantedAuthority> authorities = AuthorityUtils.createAuthorityList(userRoles);
        return authorities;
    }

    @Override
    public User mockUserObject() {

        List<UserRole> userRoles = new ArrayList<>();
        UserRole userRole = new UserRole();
        userRole.setId(1L);
        userRole.setUser(User.builder().id(1L).build());
        userRole.setRole(Role.builder().id(1L).name("MANAGER").build());
        userRoles.add(userRole);

        User user = User.builder()
                        .id(MOCKED_USER_ACCESS_TOKEN_USER_ID).email("test@test.com")
                        .name("tester").password(new Password("1113333ddd1")).active("1").organization(null)
                        .userRoles(userRoles)
                        .build();

        return user;
    }


    protected TestRestTemplate testRestTemplate;
    protected MockMvc mockMvc;

    @Override
    public String mockAccessToken(String clientName, String clientPassword, String username, String password) throws Exception {

        if(this.mockMvc == null){
            throw new Exception("mockMvc must be initially injected.");
        }

        MultiValueMap<String, String> request = new LinkedMultiValueMap<>();
        request.set("username", username);
        request.set("password", password);
        request.set("grant_type", "password");

        ResultActions result
                = this.mockMvc.perform(post("/oauth/token-endpoint")
                .params(request)
                .with(httpBasic(clientName,clientPassword))
                .accept("application/json;charset=UTF-8"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json;charset=UTF-8"));

        String resultString = result.andReturn().getResponse().getContentAsString();

        JacksonJsonParser jsonParser = new JacksonJsonParser();
        return jsonParser.parseMap(resultString).get("access_token").toString();
    }

    @Override
    public String mockAccessTokenOnPersistence(String authUrl, String clientName, String clientPassword, String username, String password) throws Exception {
        if(authUrl == null){
            throw new Exception("authUrl must be indicated for the integration test");
        }

        if(this.testRestTemplate == null){
            throw new Exception("testRestTemplate must be injected in the access-token-way integration test");
        }

        MultiValueMap<String, String> request = new LinkedMultiValueMap<>();
        request.set("username", username);
        request.set("password", password);
        request.set("grant_type", "password");

        @SuppressWarnings("unchecked")
        Map<String, Object> token = this.testRestTemplate.withBasicAuth(clientName, clientPassword)
                .postForObject(authUrl + "/oauth/token", request, Map.class);

        Assert.assertNotNull("Wrong credentials with DB : " + token, token.get("access_token"));

        return (String) token.get("access_token");
    }
}
