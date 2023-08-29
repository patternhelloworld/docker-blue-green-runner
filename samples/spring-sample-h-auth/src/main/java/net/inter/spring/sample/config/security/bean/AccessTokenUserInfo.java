package net.inter.spring.sample.config.security.bean;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import net.inter.spring.sample.microservice.auth.organization.entity.Organization;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;


/*
* 	해당 클래스는 samplewave-resource 프로젝트에서도, 동일 하게  net.inter.spring.sample.model.dto.security 에 위치해야 한다.
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


	private Long id;

	public Long getId() {
		return id;
	}
	public void setId(Long id) {
		this.id = id;
	}

	private Organization organization;

	public Organization getOrganization() {
		return organization;
	}

	public void setOrganization(Organization organization) {
		this.organization = organization;
	}
}
