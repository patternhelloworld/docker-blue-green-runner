package com.runner.spring.sample;

import org.assertj.core.util.Arrays;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.test.annotation.IfProfileValue;
import org.springframework.test.context.junit4.SpringRunner;

import static org.assertj.core.api.Assertions.assertThat;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ApplicationTests {

	@Autowired
	private TestRestTemplate restTemplate;

	@Test
	public void contextLoads() {

	}

	@Test
	public void 유효한_프로필인지_확인() {
		//when
		String profile = this.restTemplate.getForObject("/systemProfile", String.class);
		//then
		assertThat(checkProfileValidation(profile)).isEqualTo(true);
	}

	private Boolean checkProfileValidation(String profile) {
		String[] profiles = new String[]  {"local", "alpha", "production"};
		return Arrays.asList(profiles).contains(profile);

	}
}
