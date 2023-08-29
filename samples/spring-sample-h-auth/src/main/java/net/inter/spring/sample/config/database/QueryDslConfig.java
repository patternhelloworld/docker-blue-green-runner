package net.inter.spring.sample.config.database;

import com.querydsl.jpa.impl.JPAQueryFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Configuration
public class QueryDslConfig {

    @PersistenceContext(unitName = "authEntityManager")
    private EntityManager authEntityManager;

    @Bean
    public JPAQueryFactory authJpaQueryFactory() {
        return new JPAQueryFactory(authEntityManager);
    }

    @Bean
    public JPAQueryFactory jpaQueryFactory() {
        return new JPAQueryFactory(authEntityManager);
    }
}
