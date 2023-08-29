package net.inter.spring.sample.microservice.auth.user.dto;

import lombok.Data;
import java.util.List;

@Data
public class PaginatedUser {
    private List<DisApprovedUser> content;
    private int pageNum;
    private int pageSize;
    private int totalPages;
    private long totalUserCounts;
}
