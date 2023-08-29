package net.inter.spring.sample.microservice.auth.user.dao;

import net.inter.spring.sample.microservice.auth.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.querydsl.QuerydslPredicateExecutor;
import org.springframework.data.repository.query.Param;


import java.util.Optional;


public interface UserRepository extends JpaRepository<User, Long>, QuerydslPredicateExecutor<User> {

    Optional<User> findByEmail(String email);

    // @Modifying : JPA 기본 동작이 select - update로 이루어져있기 때문에 바로 update만 하겠다고 알려주는 애너테이션
    @Modifying
    @Query(value = "UPDATE sample_h_auth.users users SET users.active = :active " +
            "WHERE users.id IN :ids " +
            "AND users.organization_id = :organizationId ",
            nativeQuery = true)
    void updateSelectedUsersActiveStatus(@Param("ids") Long[] ids, @Param("active") String active, @Param("organizationId") Long organizationId);

    @Modifying
    @Query(value = " UPDATE sample_h_auth.users users " +
            " INNER JOIN sample_h_auth.user_role userRole" +
            " ON users.id = userRole.user_id" +
            " SET users.active = :active " +
            " WHERE  users.organization_id = :organizationId " +
            " AND userRole.role_id <> 2" +
            " AND userRole.role_id <> 3" +
            " AND userRole.role_id <> 8" ,
            nativeQuery = true)
    void updateAllUsersActiveStatus(@Param("active")String active, @Param("organizationId")Long organizationId);



}