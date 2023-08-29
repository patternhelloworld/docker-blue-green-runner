package net.inter.spring.sample.microservice.auth.role.dao;

import net.inter.spring.sample.util.CommonConstant;
import net.inter.spring.sample.microservice.auth.role.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;


public interface RoleRepository extends JpaRepository<Role, Long> {

}