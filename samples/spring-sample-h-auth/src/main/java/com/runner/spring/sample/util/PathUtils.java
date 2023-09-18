package com.runner.spring.sample.util;

import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;

import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

@Component
public class PathUtils {

    public static boolean matches(List<String> patterns, String url) {
        AntPathMatcher pathMatcher = new AntPathMatcher();
        AtomicReference<Boolean> result = new AtomicReference<>(false);
        patterns.forEach(pattern -> {
            if (pathMatcher.match(pattern, url)) {
                result.set(true);
            }
        });
        return result.get();
    }

}
