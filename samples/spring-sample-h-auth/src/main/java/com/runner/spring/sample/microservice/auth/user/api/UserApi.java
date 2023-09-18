package com.runner.spring.sample.microservice.auth.user.api;

import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import com.runner.spring.sample.config.security.bean.AccessTokenUserInfoValidator;
import com.runner.spring.sample.exception.data.ResourceNotFoundException;
import com.runner.spring.sample.microservice.auth.user.dao.UserRepository;
import com.runner.spring.sample.microservice.auth.user.dao.UserService;
import com.runner.spring.sample.microservice.auth.user.dto.UserDTO;
import com.runner.spring.sample.microservice.auth.user.entity.User;
import com.runner.spring.sample.util.CommonConstant;
import com.runner.spring.sample.util.CustomUtils;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2RefreshToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
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


    @GetMapping("/users/current")
    @AccessTokenUserInfoValidator
    public UserDTO.CurrentOneRes getUserSelf(@AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo, OAuth2Authentication authentication) throws ResourceNotFoundException {

       Integer accessTokenRemainingSeconds = null;

        if (authentication != null) {
           OAuth2AccessToken oAuth2AccessToken = tokenStore.getAccessToken(authentication);

            if (oAuth2AccessToken != null) {
                accessTokenRemainingSeconds = oAuth2AccessToken.getExpiresIn();
            }
        }

        return new UserDTO.CurrentOneRes(userRepository.findByEmail(accessTokenUserInfo.getUsername())
                .orElseThrow(() -> new ResourceNotFoundException("User not found")), accessTokenRemainingSeconds);

    }

    @GetMapping("/users")
    @AccessTokenUserInfoValidator
    public Page<UserDTO.ListRes> getUserList(@RequestParam(value = "skipPagination", required = false, defaultValue = "false") Boolean skipPagination,
                                             @RequestParam(value = "pageNum", required = false, defaultValue = CommonConstant.COMMON_PAGE_NUM) Integer pageNum,
                                             @RequestParam(value = "pageSize", required = false, defaultValue = CommonConstant.COMMON_PAGE_SIZE) Integer pageSize,
                                             @RequestParam(value = "userSearchFilter", required = false) String userSearchFilter,
                                             @RequestParam(value = "sorterValueFilter", required = false) String sorterValueFilter,
                                             @AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo)
            throws JsonProcessingException, ResourceNotFoundException {

        return userService.findUsersByPageRequest(skipPagination, pageNum, pageSize, userSearchFilter, sorterValueFilter, accessTokenUserInfo).map(UserDTO.ListRes::new);
    }


    @GetMapping("/admin/users/{id}")
    @AccessTokenUserInfoValidator
    public ResponseEntity<User> getUserById(@PathVariable(value = "id") Long userId, @AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo)
            throws ResourceNotFoundException {

        User userDTO = userService.findById(userId);

        // 슈퍼 어드민인지 검증(슈퍼어드민이면 true 아니면 false)
        if (!userService.checkSuperAdminFromAccessTokeUserInfo(accessTokenUserInfo)) {
            // GET 하고자 하는 대상 유저의 조직이 없거나, 세션 사용자의 조직과 일치하지 않을 경우 이는 슈퍼 어드민이 아닌 사용자가 다른 조직의 사용자를 조회하고자 하는 경우로
            // UnauthorizedException 을 발생
/*            if (userDTO.getOrganization_id() == null || !userDTO.getOrganization_id().equals(accessTokenUserInfo.getOrganization_id())) {
                throw new UnauthorizedException("REGISTERED_ADMIN cannot retrieve users in other organizations");
            }*/
        }

        return ResponseEntity.ok().body(userDTO);

    }



    @GetMapping("/user/logout")
    public Map<String, Boolean> logoutUser(HttpServletRequest request) {

        Map<String, Boolean> response = new HashMap<>();

        response.put("logout", Boolean.TRUE);

        try {
            String authorization = request.getHeader("Authorization");
            if (authorization != null && authorization.contains("Bearer")) {
                String tokenValue = authorization.replace("Bearer", "").trim();

                OAuth2AccessToken accessToken = tokenStore.readAccessToken(tokenValue);
                if (accessToken != null) {
                    tokenStore.removeAccessToken(accessToken);

                    OAuth2RefreshToken refreshToken = accessToken.getRefreshToken();
                    if (refreshToken != null) {
                        tokenStore.removeRefreshToken(refreshToken);
                    }
                }
            }
        } catch (Exception e) {
            response.put("logout", Boolean.FALSE);
            CustomUtils.createNonStoppableErrorMessage("로그 아웃 도중 오류 발생", e);
        }
        return response;
    }

    @PostMapping("/user/register")
    public UserDTO.CreateRes create(@Valid @RequestBody final UserDTO.CreateReq dto){
        return new UserDTO.CreateRes(userService.create(dto.toEntity()));
    }

    @PutMapping("/users/{id}")
    public UserDTO.UpdateRes update(@PathVariable final long id, @Valid @RequestBody final UserDTO.UpdateReq dto)
            throws ResourceNotFoundException {
        return userService.update(id, dto);
    }

}
