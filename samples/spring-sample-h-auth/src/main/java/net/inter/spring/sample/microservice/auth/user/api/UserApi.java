package net.inter.spring.sample.microservice.auth.user.api;

import com.fasterxml.jackson.core.JsonProcessingException;

import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
import net.inter.spring.sample.microservice.auth.user.dao.UserService;
import net.inter.spring.sample.microservice.auth.user.dto.UserDTO;

import net.inter.spring.sample.exception.data.ResourceNotFoundException;

import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfoValidator;

import net.inter.spring.sample.util.CommonConstant;
import net.inter.spring.sample.util.CustomUtils;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.data.domain.Page;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2RefreshToken;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;


import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class UserApi {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TokenStore tokenStore;


    @PostMapping("/users")
    @AccessTokenUserInfoValidator
    public UserDTO.Res create(@RequestBody UserDTO.UserCreateReq dto)
            throws ResourceNotFoundException {
        return new UserDTO.Res(userRepository.save(dto.toEntity()));
    }

    @GetMapping("/user")
    @AccessTokenUserInfoValidator
    public UserDTO.Res getUserSelf(@AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo) throws ResourceNotFoundException {

        return new UserDTO.Res(userRepository.findByEmail(accessTokenUserInfo.getUsername())
                .orElseThrow(() -> new ResourceNotFoundException("User not found")));

    }

    @GetMapping("/users")
    @AccessTokenUserInfoValidator
    public Page<UserDTO.Res> getUserList(@RequestParam(value = "skipPagination", required = false, defaultValue = "false") Boolean skipPagination,
                                  @RequestParam(value = "pageNum", required = false, defaultValue = CommonConstant.COMMON_PAGE_NUM) Integer pageNum,
                                  @RequestParam(value = "pageSize", required = false, defaultValue = CommonConstant.COMMON_PAGE_SIZE) Integer pageSize,
                                  @RequestParam(value = "userSearchFilter", required = false) String userSearchFilter,
                                  @RequestParam(value = "sorterValueFilter", required = false) String sorterValueFilter,
                                  @AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo)
            throws JsonProcessingException, ResourceNotFoundException {

        return userService.findUsersByPageRequest(skipPagination, pageNum, pageSize, userSearchFilter, sorterValueFilter, accessTokenUserInfo).map(UserDTO.Res::new);
    }

    @GetMapping("/user/logout")
    public Map<String, Boolean> logoutUser(HttpServletRequest request) {

        Map<String, Boolean> response = new HashMap<>();

        try {
            String authorization = request.getHeader("Authorization");
            if (authorization != null && authorization.contains("Bearer")) {
                String tokenValue = authorization.replace("Bearer", "").trim();

                OAuth2AccessToken accessToken = tokenStore.readAccessToken(tokenValue);
                tokenStore.removeAccessToken(accessToken);

                //OAuth2RefreshToken refreshToken = tokenStore.readRefreshToken(tokenValue);
                OAuth2RefreshToken refreshToken = accessToken.getRefreshToken();
                tokenStore.removeRefreshToken(refreshToken);
            }
        } catch (Exception e) {
            response.put("logout", Boolean.FALSE);
            CustomUtils.createNonStoppableErrorMessage("로그 아웃 도중 오류 발생", e);
        }

        response.put("logout", Boolean.TRUE);

        return response;
    }


}
