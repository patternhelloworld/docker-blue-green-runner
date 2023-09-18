package com.runner.spring.sample.unit.user;

import com.runner.spring.sample.microservice.auth.user.dao.UserRepository;
import com.runner.spring.sample.microservice.auth.user.dao.UserService;
import com.runner.spring.sample.microservice.auth.user.dto.UserDTO;
import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.runner.spring.sample.util.auth.MockAuth;
import com.runner.spring.sample.util.auth.UnitMockAuth;
import com.runner.spring.sample.microservice.auth.user.api.UserApi;
import com.runner.spring.sample.exception.handler.GlobalExceptionHandler;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import org.codehaus.jackson.map.ObjectMapper;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.core.MethodParameter;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;

import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2RefreshToken;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.test.context.event.annotation.BeforeTestMethod;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import java.util.*;

import static org.hamcrest.CoreMatchers.is;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;


@RunWith(MockitoJUnitRunner.class)
public class UserApiTest {

/*    @Rule
    public MockitoRule rule = MockitoJUnit.rule();*/

    @InjectMocks
    private UserApi userApi;

    @Mock
    private UserService userService;
    @Mock
    private UserRepository userRepository;


    private MockMvc mockMvc;
    private AccessTokenUserInfo accessTokenUserInfo;


    // Controller에 @AuthenticationPrincipal을 Injection 한다.
    private HandlerMethodArgumentResolver putAuthenticationPrincipal = new HandlerMethodArgumentResolver() {
        @Override
        public boolean supportsParameter(MethodParameter parameter) {
            return parameter.getParameterType().isAssignableFrom(AccessTokenUserInfo.class);
        }
        @Override
        public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                      NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {
            return accessTokenUserInfo;
        }
    };


    @BeforeTestMethod
    public void beforeMethod() {
    }

    @Before
    public void setUp() throws Exception {

        MockitoAnnotations.initMocks(this);

        // 기본 권한만 부여된 사용자로 시작한다.
        MockAuth userUtils = new UnitMockAuth();

        User u = userUtils.mockUserObject();
        // putAuthenticationPrincipal 에 Inject
        accessTokenUserInfo = userUtils.mockAuthenticationPrincipal(u);

        mockMvc = MockMvcBuilders.standaloneSetup(userApi)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setCustomArgumentResolvers(putAuthenticationPrincipal)
                .build();

    }


    @Test
    public void getUserOne_조회_200() throws Exception {

        String userEmail = "test@test.com";
        User mockUser = User.builder().email(userEmail).build();
        mockUser.setEmail(userEmail);

        //given : anyString() 자리에 "test@test.com" 이 들어가면 통과하지만, 임의의 다른 String "test2@test.com" 을 넣으면 실패한다.
        // 이는 실제 UserController 에 해당 API 에 debug 포인트를 설정하면 알 수 있다.
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(mockUser));

        // when, then
        mockMvc.perform(get("/api/v1/users/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(userEmail));

    }

    @Test
    public void getUserList_조회_200() throws Exception {

        // Given : 특정 값이 주어지고
        List<User> mockUsers = new ArrayList<>();
        mockUsers.add(User.builder()
                .email("test@test.com")
                .name("tester")
                .build());
        mockUsers.add(User.builder()
                .email("test2@test.com")
                .name("tester2")
                .build());

        // When : 어떤 이벤트가 발생했을 때
        when(userService.findUsersByPageRequest(any(), anyInt(), anyInt(), any(), any(), any()))
                // Then : 이 결과를 보장해야 한다.
                .thenReturn(new PageImpl<>(mockUsers));

        // 보장되는 지 테스트를 한다.
        mockMvc.perform(get("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("content[0].email").value("test@test.com"))
                .andExpect(jsonPath("content[0].name").value("tester"))
                .andExpect(jsonPath("content[1].email").value("test2@test.com"))
                .andExpect(jsonPath("content[1].name").value("tester2"));

    }

    @Test
    public void updateUserTest() throws Exception {

        ObjectMapper objectMapper = new ObjectMapper();

        long userId = 1L;

        UserDTO.UpdateReq updateReq = new UserDTO.UpdateReq("newemail@example.com","New Name");

        when(userService.update(anyLong(), any()))
                .thenReturn(new UserDTO.UpdateRes(User.builder().id(userId).build()));

        mockMvc.perform(put("/api/v1/users/" + userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                        .andDo(print()).andExpect(status().isOk())
                        .andExpect(jsonPath("id").value(1));
    }

    @Mock
    private TokenStore tokenStore;

    @Test
    public void testLogoutUserSuccess() throws Exception {

        String tokenValue = "sampleToken";

        OAuth2AccessToken mockAccessToken = Mockito.mock(OAuth2AccessToken.class);
        OAuth2RefreshToken mockRefreshToken = Mockito.mock(OAuth2RefreshToken.class);

        when(tokenStore.readAccessToken(tokenValue)).thenReturn(mockAccessToken);
        when(mockAccessToken.getRefreshToken()).thenReturn(mockRefreshToken);

        mockMvc.perform(get("/api/v1/user/logout")
                        .header("Authorization", "Bearer " + tokenValue))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.logout", is(true)));

        Mockito.verify(tokenStore).removeAccessToken(mockAccessToken);
        Mockito.verify(tokenStore).removeRefreshToken(mockRefreshToken);
    }

    @Test
    public void testLogoutUserFailure() throws Exception {
        String tokenValue = "sampleToken";

        when(tokenStore.readAccessToken(tokenValue)).thenThrow(new RuntimeException("Sample exception"));

        mockMvc.perform(get("/api/v1/user/logout")
                        .header("Authorization", "Bearer " + tokenValue))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.logout", is(false)));
    }


}