package com.runner.spring.sample.config.security.dao;

import com.runner.spring.sample.config.security.entity.OauthRemovedAccessToken;

import org.springframework.data.jpa.repository.JpaRepository;


public interface OauthRemovedAccessTokenRepository extends JpaRepository<OauthRemovedAccessToken,String>  {

}
