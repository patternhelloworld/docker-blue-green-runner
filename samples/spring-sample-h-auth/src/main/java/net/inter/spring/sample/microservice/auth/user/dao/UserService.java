package net.inter.spring.sample.microservice.auth.user.dao;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.querydsl.core.BooleanBuilder;
import com.querydsl.jpa.JPQLQuery;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.SneakyThrows;
import net.inter.spring.sample.mapper.auth.user.UserMapper;
import net.inter.spring.sample.microservice.auth.user.dto.*;
import net.inter.spring.sample.microservice.auth.user.entity.QUser;
import net.inter.spring.sample.microservice.auth.user.entity.User;

import net.inter.spring.sample.config.security.CustomSecurityValue;


import net.inter.spring.sample.util.CommonConstant;

import net.inter.spring.sample.exception.data.ResourceNotFoundException;


import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import net.inter.spring.sample.util.CustomUtils;

import net.inter.spring.sample.util.ValidatorUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;


import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import javax.annotation.PostConstruct;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import java.util.*;

import org.springframework.data.jpa.repository.support.QuerydslRepositorySupport;

@Service
public class UserService extends QuerydslRepositorySupport implements UserDetailsService {

    @Autowired
    @Qualifier(value = "authEntityManagerFactory")
    private EntityManager em;

    @Autowired
    private UserRepository userRepository;


    @Qualifier("authJpaQueryFactory")
    @Autowired
    private JPAQueryFactory jpaQueryFactory;

    @Autowired
    private ValidatorUtils validatorUtils;

    public UserService() {
        super(User.class);
    }

    @Override
    @PersistenceContext(unitName = "authEntityManager")
    public void setEntityManager(EntityManager entityManager) {
        super.setEntityManager(entityManager);
    }

    /*
    *
    *   1. 사용자 조회
    *
    * */

    public Boolean checkSuperAdminFromAccessTokeUserInfo(AccessTokenUserInfo accessTokenUserInfo) throws ResourceNotFoundException {

        Boolean superAdmin = false;

        Set<String> userRoles = AuthorityUtils.authorityListToSet(accessTokenUserInfo.getAuthorities());

        if (userRoles != null && userRoles.size() > 0) {
            for (String role : userRoles) {
                if (role.equals(CommonConstant.SUPER_ADMIN_ROLE_NAME)) {
                    superAdmin = true;
                }
            }
        }

        return superAdmin;
    }




    // https://velog.io/@jurlring/TransactionalreadOnly-true%EC%97%90%EC%84%9C-readOnly-true%EB%8A%94-%EB%AC%B4%EC%8A%A8-%EC%97%AD%ED%95%A0%EC%9D%B4%EA%B3%A0-%EA%BC%AD-%EC%8D%A8%EC%95%BC%ED%95%A0%EA%B9%8C
    @Transactional(value = "authTransactionManager", readOnly = true)
    public Page<User> findUsersByPageRequest(Boolean skipPagination,
                                             Integer pageNum,
                                             Integer pageSize,
                                             String userSearchFilter,
                                             String sorterValueFilter,
                                             AccessTokenUserInfo accessTokenUserInfo) throws JsonProcessingException, ResourceNotFoundException {

        final QUser qUser = QUser.user;

        JPQLQuery<User> query = jpaQueryFactory.selectFrom(qUser);

        ObjectMapper objectMapper = new ObjectMapper();

        if(!CustomUtils.isEmpty(userSearchFilter)) {


            UserSearchFilter deserializedUserSearchFilter = (UserSearchFilter) objectMapper.readValue(userSearchFilter, UserSearchFilter.class);

            if (!CustomUtils.isEmpty(deserializedUserSearchFilter.getEmail())) {
                query.where(qUser.email.likeIgnoreCase("%" + deserializedUserSearchFilter.getEmail() + "%"));
            }
            if (!CustomUtils.isEmpty(deserializedUserSearchFilter.getName())) {
                query.where(qUser.name.likeIgnoreCase("%" + deserializedUserSearchFilter.getName() + "%"));
            }

        }


        Sort.Direction sortDirection = Sort.Direction.DESC;
        String sortedColumn = "updated_at";
        if(!CustomUtils.isEmpty(sorterValueFilter)) {
            SorterValueFilter deserializedSorterValueFilter = (SorterValueFilter) objectMapper.readValue(sorterValueFilter, SorterValueFilter.class);

            sortDirection = deserializedSorterValueFilter.getAsc() ?  Sort.Direction.ASC : Sort.Direction.DESC;
            sortedColumn = deserializedSorterValueFilter.getColumn();
        }


        // Pagination
        if (skipPagination) {
            pageNum = Integer.parseInt(CommonConstant.COMMON_PAGE_NUM);
            pageSize = Integer.parseInt(CommonConstant.COMMON_PAGE_SIZE_DEFAULT_MAX);
        }
        PageRequest pageRequest = PageRequest.of(pageNum - 1, pageSize, Sort.by(sortDirection, sortedColumn));

        return new PageImpl<>(getQuerydsl().applyPagination(pageRequest, query).fetch());

    }

    @Transactional(value = "authTransactionManager", readOnly = true)
    public Page<User> findUsersByPageRequest2(Boolean skipPagination,
                                                Integer pageNum,
                                                Integer pageSize,
                                                String userSearchFilter,
                                                AccessTokenUserInfo accessTokenUserInfo)
            throws JsonProcessingException, ResourceNotFoundException {

        BooleanBuilder builder = new BooleanBuilder();
        final QUser qUser = QUser.user;

        ObjectMapper objectMapper = new ObjectMapper();

        if(!CustomUtils.isEmpty(userSearchFilter)) {

            UserSearchFilter deserializedUserSearchFilter = (UserSearchFilter) objectMapper.readValue(userSearchFilter, UserSearchFilter.class);

            if (!CustomUtils.isEmpty(deserializedUserSearchFilter.getEmail())) {
                builder.and(qUser.email.like("%" + deserializedUserSearchFilter.getEmail() + "%"));
            }
            if (!CustomUtils.isEmpty(deserializedUserSearchFilter.getName())) {
                builder.and(qUser.name.like("%" + deserializedUserSearchFilter.getName() + "%"));
            }
        }

        // Pagination
        if (skipPagination) {
            pageNum = Integer.parseInt(CommonConstant.COMMON_PAGE_NUM);
            pageSize = Integer.parseInt(CommonConstant.COMMON_PAGE_SIZE_DEFAULT_MAX);
        }
        PageRequest pageRequest = PageRequest.of(pageNum - 1, pageSize, Sort.by(Sort.Direction.DESC, "updatedAt"));

        return userRepository.findAll(builder, pageRequest);
    }


    /*
        2. 사용자 생성
    * */
    public User createUser(User user){
        return userRepository.save(user);
    }

    public void handleFailCnt(String userName) throws UsernameNotFoundException {

        User user = userRepository.findByEmail(userName).orElseThrow(() -> new UsernameNotFoundException("Email " + userName + " not found"));

        int currentFailCnt = user.getFail_cnt() == null || user.getFail_cnt() == 0 ? 1 : user.getFail_cnt()+1;

        if(currentFailCnt < CustomSecurityValue.loginMaxRetry.getValue()) {
            user.setFail_cnt(currentFailCnt);
        }else{

            user.setFail_cnt(currentFailCnt);
            user.setActive("0");
        }
    }

    public void resetFailCnt(String userName) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(userName).orElseThrow(() -> new UsernameNotFoundException("Email " + userName + " not found"));
        user.setFail_cnt(0);
    }


    /*
      5. Oauth2 커스토 마이징
    * */
    @Override
    @SneakyThrows
    public UserDetails loadUserByUsername(String userName) throws UsernameNotFoundException{

        User user = getUserEntityByEmail(userName);

        return buildUserForAuthentication(user, getAuthorities(user));

    }
    public User getUserEntityByEmail(String email){

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Email " + email + " not found"));
    }

    private AccessTokenUserInfo buildUserForAuthentication(User user, Collection<? extends GrantedAuthority> authorities) {
        String username = user.getEmail();
        String password = user.getPassword().getValue();
        boolean enabled = true;
        boolean accountNonExpired = true;
        boolean credentialsNonExpired = true;
        boolean accountNonLocked = true;

        AccessTokenUserInfo authUser = new AccessTokenUserInfo(username, password, enabled, accountNonExpired, credentialsNonExpired,
                accountNonLocked, authorities);

        authUser.setId(user.getId());
        authUser.setOrganization_id(user.getOrganization_id());

        return authUser;
    }

    private static Collection<? extends GrantedAuthority> getAuthorities(User user) {
        String[] userRoles = new String[]{};
        Collection<GrantedAuthority> authorities = AuthorityUtils.createAuthorityList(userRoles);
        return authorities;
    }

    @PostConstruct
    public void init() {

    }
}