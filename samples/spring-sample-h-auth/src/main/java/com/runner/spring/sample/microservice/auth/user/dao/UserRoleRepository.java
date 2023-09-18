package com.runner.spring.sample.microservice.auth.user.dao;

import com.runner.spring.sample.microservice.auth.user.entity.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;


public interface UserRoleRepository extends JpaRepository<UserRole, Long> {

}
