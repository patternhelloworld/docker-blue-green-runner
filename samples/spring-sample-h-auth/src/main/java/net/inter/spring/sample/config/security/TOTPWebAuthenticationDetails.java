package net.inter.spring.sample.config.security;

import lombok.Getter;
import org.springframework.security.web.authentication.WebAuthenticationDetails;
import org.springframework.util.StringUtils;
import javax.servlet.http.HttpServletRequest;

/**
 * 로그인폼에 있는 "totp-verification-code" 정보를 읽어온다.
 */
@Getter
public class TOTPWebAuthenticationDetails extends WebAuthenticationDetails {

    private static final long serialVersionUID = -6237936605503144600L;
    private Integer totpKey;

    /**
     * Records the remote address and will also set the session Id if a session
     * already exists (it won't create one).
     *
     * @param request that the authentication request was received from
     */
    public TOTPWebAuthenticationDetails(HttpServletRequest request) {
        super(request);

        // 로그인 폼에서 선언한 파라미터 명으로 request
        String totpKeyString = request.getParameter("totp-verification-code");

        if (StringUtils.hasText(totpKeyString)) {
            try {
                this.totpKey = Integer.valueOf(totpKeyString);
            } catch (NumberFormatException e) {
                this.totpKey = null;
            }
        }
    }

}