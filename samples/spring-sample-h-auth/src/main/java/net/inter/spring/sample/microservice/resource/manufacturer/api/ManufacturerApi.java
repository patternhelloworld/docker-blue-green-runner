package net.inter.spring.sample.microservice.resource.manufacturer.api;

import com.fasterxml.jackson.core.JsonProcessingException;

import net.inter.spring.sample.exception.data.ResourceNotFoundException;
import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
import net.inter.spring.sample.microservice.auth.user.dao.UserService;
import net.inter.spring.sample.microservice.auth.user.dto.UserDTO;

import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfoValidator;

import net.inter.spring.sample.util.CommonConstant;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

import org.springframework.security.oauth2.provider.token.TokenStore;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/v1")
public class ManufacturerApi {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TokenStore tokenStore;

    @Value("${specific.admin.email}")
    private String specificAdminEmail;

    // https://velog.io/@yoon_s_whan/Springboot-Oauth2-jwt-Kakao-Android

    @PostMapping("/test-create/manufacturers")
    /*    @AccessTokenUserInfoValidator*/
    public UserDTO.Res create(@RequestBody UserDTO.UserCreateReq dto)
            throws ResourceNotFoundException {
        return new UserDTO.Res(userRepository.save(dto.toEntity()));
    }

    @GetMapping("/manufacturer")
    @AccessTokenUserInfoValidator
    public UserDTO.Res getManufacturerSelf(@AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo) throws ResourceNotFoundException {

        return new UserDTO.Res(userRepository.findByEmail(accessTokenUserInfo.getUsername())
                .orElseThrow(() -> new ResourceNotFoundException("User not found")));

    }


    @GetMapping("/manufacturers")
    @AccessTokenUserInfoValidator
    public Page<UserDTO.Res> getManufacturerList(@RequestParam(value = "skipPagination", required = false, defaultValue = "false") Boolean skipPagination,
                                  @RequestParam(value = "pageNum", required = false, defaultValue = CommonConstant.COMMON_PAGE_NUM) Integer pageNum,
                                  @RequestParam(value = "pageSize", required = false, defaultValue = CommonConstant.COMMON_PAGE_SIZE) Integer pageSize,
                                  @RequestParam(value = "userSearchFilter", required = false) String userSearchFilter,
                                  @RequestParam(value = "sorterValueFilter", required = false) String sorterValueFilter,
                                  @AuthenticationPrincipal AccessTokenUserInfo accessTokenUserInfo)
            throws JsonProcessingException, ResourceNotFoundException {

        return userService.findUsersByPageRequest(skipPagination, pageNum, pageSize, userSearchFilter, sorterValueFilter, accessTokenUserInfo).map(UserDTO.Res::new);
    }


}
