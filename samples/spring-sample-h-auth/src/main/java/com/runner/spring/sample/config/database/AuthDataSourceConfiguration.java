package com.runner.spring.sample.config.database;

import com.zaxxer.hikari.HikariDataSource;

import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.SqlSessionTemplate;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.jdbc.datasource.LazyConnectionDataSourceProxy;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;

@Configuration
@MapperScan(basePackages = {"com.runner.spring.sample.mapper.auth"}, sqlSessionFactoryRef = "authSqlSessionFactory")
@EnableJpaRepositories(
        basePackages = {"com.runner.spring.sample.microservice.auth", "com.runner.spring.sample.config.security"},
        entityManagerFactoryRef = "authEntityManagerFactory",
        transactionManagerRef= "authTransactionManager"
)
public class AuthDataSourceConfiguration {

    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource.hikari.auth")
    public DataSourceProperties authDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name="authDataSource")
    @Primary
    @ConfigurationProperties("spring.datasource.hikari.auth.configuration")
    public DataSource authDataSource() {
        return new LazyConnectionDataSourceProxy(authDataSourceProperties().initializeDataSourceBuilder()
                .type(HikariDataSource.class).build());
    }

    @Primary
    @Bean(name = "authEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean authEntityManagerFactory(EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(authDataSource())
                .packages("com.runner.spring.sample.microservice.auth", "com.runner.spring.sample.config.security")
                .persistenceUnit("authEntityManager")
                .build();
    }

    @Primary
    @Bean(name = "authTransactionManager")
    public PlatformTransactionManager authTransactionManager(@Qualifier("authEntityManagerFactory") EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }


    @Bean(name="authSqlSessionFactory")
    public SqlSessionFactory authSqlSessionFactory(@Qualifier("authDataSource") DataSource authDataSource) throws Exception{
        final SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(authDataSource);
        sessionFactory.setTypeAliasesPackage("com.runner.spring.sample.mapper");

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        sessionFactory.setMapperLocations(resolver.getResources("classpath:/mapper/auth/**/*.xml"));

        return sessionFactory.getObject();
    }

    @Bean(name="authSqlSessionTemplate")
    public SqlSessionTemplate authSqlSessionTemplate(SqlSessionFactory authSqlSessionFactory) {
        return new SqlSessionTemplate(authSqlSessionFactory);
    }

}
