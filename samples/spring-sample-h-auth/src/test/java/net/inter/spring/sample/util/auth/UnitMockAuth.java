package net.inter.spring.sample.util.auth;

import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;

import java.util.Set;

public class UnitMockAuth extends AbstractMockAuth {



    public UnitMockAuth(){

    }

    @Override
    public AccessTokenUserInfo mockAuthenticationPrincipal(User user) {
        return super.mockAuthenticationPrincipal(user);
    }

    @Override
    public User mockUserObject(String dynamicRoles) {
        return super.mockUserObject(dynamicRoles);
    }

}
