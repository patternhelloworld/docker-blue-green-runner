package net.inter.spring.sample.config.security.dao;

import net.inter.spring.sample.config.security.entity.CustomOAuthClientDetails;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomOauthClientDetailsRepository extends JpaRepository<CustomOAuthClientDetails, String> {

}
