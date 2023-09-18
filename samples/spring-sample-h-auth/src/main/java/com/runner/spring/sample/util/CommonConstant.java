package com.runner.spring.sample.util;

import java.util.Arrays;

public class CommonConstant {
    public static final String COMMON_PAGE_NUM = "1";
    public static final String COMMON_PAGE_SIZE = "10";

    public static final String COMMON_PAGE_SIZE_DEFAULT_MAX = "1000";

    public static final String WORKSPACE_NOT_SET_TITLE = "Unset";

    public static final Integer WORKSPACE_DEFAULT_STORAGE_TYPE = 5;
    public static final String DYNAMIC_TABLE_NUM_SYMBOL = "table_num_based_on_organization_id";

    public static final String[] DYNAMIC_USER_RELATION_TABLES = {"user_binder", "user_template", "user_workspace"};

    public static final String SUPER_ADMIN_ROLE_NAME = "AUTO_ADMIN";
    public static final String ADMIN_ROLE_NAME = "REGISTERED_ADMIN";
    public static final String[] BASIC_ROLE_NAMES = {"WORKSPACE_READ", "BINDER_READ"};

    public static final long ORGANIZATION_INVITATION_LINK_VALID_SECONDS = 3000L;
    public static final String ORGANIZATION_DEFAULT_ORGANIZATION_TYPE = "general";

}
