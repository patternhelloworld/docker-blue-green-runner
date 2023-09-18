package com.runner.spring.sample.microservice.auth.role.dao;

import com.runner.spring.sample.microservice.auth.role.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;


public interface RoleRepository extends JpaRepository<Role, Long> {

}