package net.inter.spring.sample.config.security.entity;

import org.springframework.security.oauth2.provider.client.BaseClientDetails;
import javax.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "sample_h_auth.oauth_client_details")
public class CustomOAuthClientDetails extends BaseClientDetails {

	@Id
	@Override
	@Column(name = "client_id")
	public String getClientId() {
		return super.getClientId();
	}

	@Column(name = "password_force_change")
	public String getPasswordForceChange() {
		return passwordForceChange;
	}
	public void setPasswordForceChange(String passwordForceChange) {
		this.passwordForceChange = passwordForceChange;
	}

	private String passwordForceChange;


}
