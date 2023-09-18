package com.runner.spring.sample.config.database.dialect;


import org.hibernate.dialect.PostgreSQL10Dialect;
import org.hibernate.dialect.function.SQLFunctionTemplate;
import org.hibernate.type.StandardBasicTypes;

public class PGDialect extends PostgreSQL10Dialect {

    public PGDialect() {
        super();
        registerFunction("string_agg", new SQLFunctionTemplate( StandardBasicTypes.STRING, "string_agg(?1, ?2)"));
    }
}
