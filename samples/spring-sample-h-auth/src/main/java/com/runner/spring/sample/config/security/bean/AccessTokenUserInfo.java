package com.runner.spring.sample.config.security.bean;

import com.runner.spring.sample.microservice.auth.user.dto.UserDTO;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;


/*
* 	해당 클래스는 samplewave-resource 프로젝트에서도, 동일 하게  com.runner.spring.sample.model.dto.security 에 위치해야 한다.
* */
public class AccessTokenUserInfo extends User
{
	public AccessTokenUserInfo(String username, String password, Collection<? extends GrantedAuthority> authorities) {
		super(username, password, authorities);
	}

	public AccessTokenUserInfo(String username, String password, boolean enabled, boolean accountNonExpired,
							   boolean credentialsNonExpired, boolean accountNonLocked,
							   Collection<? extends GrantedAuthority> authorities) {


		super(username, password, enabled, accountNonExpired, credentialsNonExpired, accountNonLocked, authorities);
	}


	private UserDTO.AccessTokenUser accessTokenUser;

	public UserDTO.AccessTokenUser getAccessTokenUser() {
		return accessTokenUser;
	}

	public void setAccessTokenUser(UserDTO.AccessTokenUser accessTokenUser) {
		this.accessTokenUser = accessTokenUser;
	}
}
