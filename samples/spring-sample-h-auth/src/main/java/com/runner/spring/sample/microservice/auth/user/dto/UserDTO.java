package com.runner.spring.sample.microservice.auth.user.dto;

import com.runner.spring.sample.microservice.auth.user.entity.Password;
import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;

import java.io.Serializable;
import java.sql.Timestamp;

public class UserDTO {

    @Getter
    @NoArgsConstructor(access = AccessLevel.PROTECTED)
    public static class CreateReq {

        @NotBlank(message = "이메일은 비어있으면 안됩니다.")
        @Email(message = "이메일 양식이 유효하지 않습니다.")
        private String email;
        @NotBlank(message = "이름은 비어있으면 안됩니다.")
        public String name;

        private String password;

        @Builder
        public CreateReq(String email, String name, String password) {
            this.email = email;
            this.name = name;
            this.password = password;
        }

        public User toEntity() {
            return User.builder()
                    .email(this.email)
                    .name(this.name)
                    .password(Password.builder().value(this.password).build())
                    .build();
        }

    }

    @Getter
    @NoArgsConstructor(access = AccessLevel.PROTECTED)
    @AllArgsConstructor
    public static class UpdateReq {

        @NotBlank(message = "이메일은 비어있으면 안됩니다.")
        @Email(message = "이메일 양식이 유효하지 않습니다.")
        private String email;
        @NotBlank(message = "이름은 비어있으면 안됩니다.")
        public String name;

    }

    @Getter
    public static class CreateRes {

        private Long id;

        public CreateRes(User user) {
            this.id = user.getId();
        }
    }

    @Getter
    public static class UpdateRes {

        private Long id;

        public UpdateRes(User user) {
            this.id = user.getId();
        }
    }

    @Getter
    public static class ListRes {

        private Long id;
        private String email;
        private String name;
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp createdAt;
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp updatedAt;

        public ListRes(User user) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.name = user.getName();
            this.createdAt = user.getCreatedAt();
            this.updatedAt = user.getUpdatedAt();
        }
    }

    @Getter
    public static class CurrentOneRes {

        private Long id;
        private String email;
        private String name;
        private Integer accessTokenRemainingSeconds;

        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp createdAt;
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp updatedAt;

        public CurrentOneRes(User user, Integer accessTokenRemainingSeconds) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.name = user.getName();
            this.accessTokenRemainingSeconds = accessTokenRemainingSeconds;
            this.createdAt = user.getCreatedAt();
            this.updatedAt = user.getUpdatedAt();
        }
    }

    @Getter
    @Setter
    public static class AccessTokenUser implements Serializable {

        private Long id;
        private String email;
        private String name;

        public AccessTokenUser(User user) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.name = user.getName();

        }
    }
}
