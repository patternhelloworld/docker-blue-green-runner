package com.runner.spring.sample.unit.user;

import com.runner.spring.sample.microservice.auth.role.entity.Role;
import com.runner.spring.sample.microservice.auth.user.dao.UserRepository;
import com.runner.spring.sample.microservice.auth.user.dao.UserService;
import com.runner.spring.sample.util.auth.MockAuth;
import com.runner.spring.sample.util.auth.UnitMockAuth;
import com.querydsl.jpa.impl.JPAQueryFactory;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoJUnitRunner;
import org.mockito.junit.MockitoRule;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.jpa.repository.support.Querydsl;
import org.springframework.test.context.event.annotation.BeforeTestMethod;
import org.springframework.web.context.WebApplicationContext;

import java.util.*;


import static org.assertj.core.api.Assertions.assertThat;

import static org.mockito.ArgumentMatchers.any;


@RunWith(MockitoJUnitRunner.class)

@DataJpaTest
public class UserServiceTest {

    @Rule
    public MockitoRule rule = MockitoJUnit.rule();

    @InjectMocks
    private UserService userService;

    @Mock
    private UserRepository userRepository;

    private AccessTokenUserInfo accessTokenUserInfo;

    @Autowired
    protected WebApplicationContext context;

    private MockAuth mockAuth;

    @BeforeTestMethod
    public void beforeMethod() {
    }

    @Before
    public void setUp() throws Exception {

        MockitoAnnotations.initMocks(this);

        mockAuth = new UnitMockAuth();
        Set<Role> roles = new HashSet<>();
        Role role = Role.builder().id(1L).name("USER").build();
        roles.add(role);


        accessTokenUserInfo = mockAuth.mockAuthenticationPrincipal(mockAuth.mockUserObject());

    }

    @Mock
    private JPAQueryFactory jpaQueryFactory;

    @Mock
    protected Querydsl getQuerydsl;

    @Test
    public void findUsersByPageRequest_성공() throws Exception {

/*        //given
        List<User> userList = new ArrayList<User>();
        userList.add(mockAuth.mockUserObject(null));
        userList.add(mockAuth.mockUserObject(null));
        userList.add(mockAuth.mockUserObject(null));

        Boolean skipPagination = false;
        Integer pageNum = 1;
        Integer pageSize = 5;

        // Mock the behavior of queryFactory
        final QUser qUser = QUser.user;
        when(jpaQueryFactory.selectFrom(any())).thenReturn(any());

        Sort.Direction sortDirection = Sort.Direction.DESC;
        String sortedColumn = "updated_at";

        // Pagination
        if (skipPagination) {
            pageNum = Integer.parseInt(CommonConstant.COMMON_PAGE_NUM);
            pageSize = Integer.parseInt(CommonConstant.COMMON_PAGE_SIZE_DEFAULT_MAX);
        }
        PageRequest pageRequest = PageRequest.of(pageNum - 1, pageSize, Sort.by(sortDirection, sortedColumn));
        given(getQuerydsl.applyPagination(pageRequest,any())).willReturn((JPQLQuery<Object>) userList);


        //then
        Page<User> result = userService.findUsersByPageRequest(false, 1, 5, "", "", accessTokenUserInfo);


        assertThat(userList.get(0).getEmail().equals("test@test.com")).isEqualTo(result.getContent().get(0).getEmail().equals("test@test.com"));*/

    }

/*    @Test(expected = JsonProcessingException.class)
    public void findUsersByPageRequest_userSearchFilter_예외_발생() throws JsonProcessingException {

        // given

        // when
        Page<User> page1 = userService.findUsersByPageRequest(false, 1, 5, "{aaa}", "", accessTokenUserInfo);

        // then
    }*/

/*
    @Test
    public void create_사용자_등록_성공() {
        //given
        final User dto = new User();

        given(userRepository.save(any(User.class))).willReturn(dto);

        //when
        final User user = userService.createUser(dto);

        //then
        verify(userRepository, atLeastOnce()).save(any(User.class));
        assertThat(dto).isEqualTo(user);

    }
*/




}