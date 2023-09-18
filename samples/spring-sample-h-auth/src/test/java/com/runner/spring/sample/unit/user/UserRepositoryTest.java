package com.runner.spring.sample.unit.user;

import com.runner.spring.sample.microservice.auth.user.dao.UserRepository;
import com.runner.spring.sample.microservice.auth.user.entity.QUser;
import com.runner.spring.sample.microservice.auth.user.entity.User;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;


//@DataJpaTest
@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    private final QUser qUser = QUser.user;

    @Test
    public void findByEmail_test() {
        final String email = "test@test.com";
        final User user = userRepository.findByEmail(email).get();
        assertThat(user.getEmail()).isEqualTo(email);
    }

    @Test
    public void findByEmail_notFound_test() {
        final String nonexistentEmail = "nonexistent@test.com";
        final Optional<User> optionalUser = userRepository.findByEmail(nonexistentEmail);
        assertThat(optionalUser.isPresent()).isFalse();
    }
/*
    @Test
    public void findById_test() {
        final Optional<User> optionalUser = userRepository.findById(1L);
        final User user = optionalUser.get();
        assertThat(user.getId()).isEqualTo(1L);
    }*/

/*    @Test
    public void isExistedEmail_test() {
        final String email = "test001@test.com";
        final boolean existsByEmail = userRepository.existsByEmail(Email.of(email));
        assertThat(existsByEmail).isTrue();
    }

    @Test
    public void findRecentlyRegistered_test() {
        final List<User> users = userRepository.findRecentlyRegistered(10);
        assertThat(users.size()).isLessThan(11);
    }

    @Test
    public void predicate_test_001() {
        //given
        final Predicate predicate = qUser.email.eq(Email.of("test001@test.com"));

        //when
        final boolean exists = userRepository.exists(predicate);

        //then
        assertThat(exists).isTrue();
    }

    @Test
    public void predicate_test_002() {
        //given
        final Predicate predicate = qUser.firstName.eq("test");

        //when
        final boolean exists = userRepository.exists(predicate);

        //then
        assertThat(exists).isFalse();
    }

    @Test
    public void predicate_test_003() {
        //given
        final Predicate predicate = qUser.email.value.like("test%");

        //when
        final long count = userRepository.count(predicate);

        //then
        assertThat(count).isGreaterThan(1);
    }*/


}