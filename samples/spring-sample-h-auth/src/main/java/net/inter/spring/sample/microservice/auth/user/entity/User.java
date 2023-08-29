package net.inter.spring.sample.microservice.auth.user.entity;

import com.fasterxml.jackson.annotation.*;
import lombok.*;
import net.inter.spring.sample.microservice.auth.organization.entity.Organization;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.format.annotation.DateTimeFormat;

import javax.persistence.*;
import javax.validation.constraints.*;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Entity
@Table(name="sample_h_auth.user")
@Getter
@Setter
//@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User
{
	@Id
	@GeneratedValue(strategy= GenerationType.IDENTITY)
	private Long id;

	@NotNull(message = "이름은 비어있으면 안됩니다.")
	private String name;

	private String email;

	@Embedded
	private Password password;


	@Column(length = 11, columnDefinition = "int")
	private Integer fail_cnt;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "organization_id")
	private Organization organization;


	@OneToMany(mappedBy = "user")
	private List<UserRole> userRoles = new ArrayList<>();


	@Column(length = 1, columnDefinition ="char")
	private String active;

	// 추후 사용
	@Column(name = "reset_token")
	private String resetToken;

	// 추후 사용
	@Column(name = "reset_token_time")
	@DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss", timezone = "Asia/Seoul")
	private LocalDateTime resetTokenTime;

	// 추후 사용
	@Column(name = "password_changed_at")
	@DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss", timezone = "Asia/Seoul")
	private LocalDateTime passwordChangedAt;


	@Column(name="created_at", updatable = false, insertable = false)
	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
	@CreationTimestamp
	private Timestamp createdAt;

	@Column(name="updated_at",  updatable = false, insertable = false)
	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
	@UpdateTimestamp
	private Timestamp updatedAt;


	@Builder
	public User(String name, String email, Password password, Organization organization, List<UserRole> userRoles, String active) {
		this.name = name;
		this.email = email;
		this.password = password;
		this.organization = organization;
		this.userRoles = userRoles;
		this.active = active;
	}

	public User() {

	}
}
