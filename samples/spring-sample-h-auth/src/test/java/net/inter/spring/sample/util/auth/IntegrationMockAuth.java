package net.inter.spring.sample.util.auth;

import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;


public class IntegrationMockAuth extends AbstractMockAuth {

    public IntegrationMockAuth(TestRestTemplate testRestTemplate){
        this.testRestTemplate = testRestTemplate;
    }
    public IntegrationMockAuth(MockMvc mockMvc){
        this.mockMvc = mockMvc;
    }

    @Override
    public String mockAccessToken(String clientName, String clientPassword, String username, String password) throws Exception {
        return super.mockAccessToken(clientName, clientPassword, username, password);
    }

    @Override
    public String mockAccessTokenOnPersistence(String authUrl, String clientName, String clientPassword, String username, String password) throws Exception {
        return super.mockAccessTokenOnPersistence(authUrl, clientName, clientPassword, username, password);
    }
}
