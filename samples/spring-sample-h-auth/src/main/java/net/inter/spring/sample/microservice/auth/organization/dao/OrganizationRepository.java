package net.inter.spring.sample.microservice.auth.organization.dao;

import net.inter.spring.sample.microservice.auth.organization.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.querydsl.QuerydslPredicateExecutor;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;


public interface OrganizationRepository extends JpaRepository<Organization, Long>, QuerydslPredicateExecutor<Organization> {

}