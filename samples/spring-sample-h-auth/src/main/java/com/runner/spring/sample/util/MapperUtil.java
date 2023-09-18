package com.runner.spring.sample.util;

public class MapperUtil {

    public static String userTable ="users";
    public static String getUserTableName(Long organization_id){ return userTable + "_" + organization_id;}
}
