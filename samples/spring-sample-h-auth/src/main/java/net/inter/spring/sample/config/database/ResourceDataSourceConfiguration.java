package net.inter.spring.sample.config.database;

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
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.jdbc.datasource.LazyConnectionDataSourceProxy;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;


@Configuration
@MapperScan(basePackages = {"net.inter.spring.sample.mapper.resource"}, sqlSessionFactoryRef = "resourceSqlSessionFactory")
@EnableJpaRepositories(
        basePackages = {"net.inter.spring.sample.microservice.resource"},
        entityManagerFactoryRef = "resourceEntityManagerFactory",
        transactionManagerRef= "resourceTransactionManager"
)
public class ResourceDataSourceConfiguration {

    @Bean
    @ConfigurationProperties("spring.datasource.hikari.resource")
    public DataSourceProperties resourceDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    @ConfigurationProperties("spring.datasource.hikari.resource.configuration")
    public DataSource resourceDataSource() {
        return new LazyConnectionDataSourceProxy(resourceDataSourceProperties().initializeDataSourceBuilder()
                .type(HikariDataSource.class).build());
    }


    @Bean(name = "resourceEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean resourceEntityManagerFactory(EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(resourceDataSource())
                .packages("net.inter.spring.sample.microservice.resource")
                .persistenceUnit("resourceEntityManager")
                .build();
    }


    @Bean(name = "resourceTransactionManager")
    public PlatformTransactionManager resourceTransactionManager(@Qualifier("resourceEntityManagerFactory") EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }


    @Bean(name="resourceSqlSessionFactory")
    public SqlSessionFactory resourceSqlSessionFactory(@Qualifier("resourceDataSource") DataSource resourceDataSource) throws Exception {
        final SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(resourceDataSource);
        sessionFactory.setTypeAliasesPackage("net.inter.spring.sample.mapper");

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        sessionFactory.setMapperLocations(resolver.getResources("classpath:/mapper/resource/**/*.xml"));

        return sessionFactory.getObject();
    }

    @Bean(name="resourceSqlSessionTemplate")
    public SqlSessionTemplate resourceSqlSessionTemplate(SqlSessionFactory resourceSqlSessionFactory) {
        return new SqlSessionTemplate(resourceSqlSessionFactory);
    }
}