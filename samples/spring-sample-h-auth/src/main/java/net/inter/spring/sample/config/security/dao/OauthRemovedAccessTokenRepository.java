package net.inter.spring.sample.config.security.dao;

import net.inter.spring.sample.config.security.entity.OauthRemovedAccessToken;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.querydsl.QuerydslPredicateExecutor;


public interface OauthRemovedAccessTokenRepository extends JpaRepository<OauthRemovedAccessToken,String>  {

}
