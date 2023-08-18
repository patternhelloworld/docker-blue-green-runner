package net.inter.spring.sample.unit.user;

import net.inter.spring.sample.microservice.auth.user.api.UserApi;
import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
import net.inter.spring.sample.microservice.auth.user.dao.UserService;
import net.inter.spring.sample.util.auth.MockAuth;
import net.inter.spring.sample.util.auth.UnitMockAuth;
import net.inter.spring.sample.exception.handler.GlobalExceptionHandler;
import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.core.MethodParameter;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;

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

        // putAuthenticationPrincipal 에 Inject
        accessTokenUserInfo = userUtils.mockAuthenticationPrincipal(userUtils.mockUserObject(null));

        mockMvc = MockMvcBuilders.standaloneSetup(userApi)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setCustomArgumentResolvers(putAuthenticationPrincipal)
                .build();

    }


    @Test
    public void getUserOne_조회_200() throws Exception {

        String userEmail = "test@test.com";
        User mockUser = new User();
        mockUser.setEmail(userEmail);

        //given : anyString() 자리에 "test@test.com" 이 들어가면 통과하지만, 임의의 다른 String "test2@test.com" 을 넣으면 실패한다.
        // 이는 실제 UserController 에 해당 API 에 debug 포인트를 설정하면 알 수 있다.
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(mockUser));

        // when, then
        mockMvc.perform(get("/api/v1/user"))
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

/*    @Test
    public void getUserList_조회_200() throws Exception {

        //given

        // when, then
        mockMvc.perform(get("/api/v1/admin/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().is(200));

    }

    @Test
    public void getUserById_사용자_없음_404_오류() throws Exception {

        //given
        given(userService.findById(anyLong())).willThrow(ResourceNotFoundException.class);

        // when, then
        mockMvc.perform(get("/api/v1/admin/users/" + anyLong())
                .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().is(404));

    }

    @Test
    public void getUserById_조직이_일치할_경우_사용자_조회_성공() throws Exception {
        //given
        User dtoUser = new User();
        dtoUser.setOrganization_id(UnitMockAuth.MOCKED_USER_ACCESS_TOKEN_ORGANIZATION_ID);

        given(userService.findById(anyLong())).willReturn(dtoUser);

        // when, then
        mockMvc.perform(get("/api/v1/admin/users/" +  anyLong())//.with(user(accessTokenUserInfo))
                .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email", is(dtoUser.getEmail())));
    }*/


}