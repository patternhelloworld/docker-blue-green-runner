package com.runner.spring.sample.config.security.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import java.sql.Timestamp;

@Entity
@Getter
@Setter
@Table(name="spring_sample_h_auth.oauth_removed_access_token")
public class OauthRemovedAccessToken {
    @Id
    @Column(name="access_token", columnDefinition = "varchar(255)")
    private String accessToken;

    @Column(name="user_name", columnDefinition = "varchar(255)")
    private String userName;

    private int reason;

    @Column(name = "created_at", insertable = false, updatable = false)
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    @CreationTimestamp
    private Timestamp createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    @UpdateTimestamp
    private Timestamp updatedAt;

}
