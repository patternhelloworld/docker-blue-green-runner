package com.runner.spring.sample.util.auth;

import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;

public class UnitMockAuth extends AbstractMockAuth {



    public UnitMockAuth(){

    }

    @Override
    public AccessTokenUserInfo mockAuthenticationPrincipal(User user) {
        return super.mockAuthenticationPrincipal(user);
    }

    @Override
    public User mockUserObject() {
        return super.mockUserObject();
    }

}
