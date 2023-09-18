package com.runner.spring.sample.microservice.auth.organization.dao;

import com.runner.spring.sample.microservice.auth.organization.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.querydsl.QuerydslPredicateExecutor;


public interface OrganizationRepository extends JpaRepository<Organization, Long>, QuerydslPredicateExecutor<Organization> {

}