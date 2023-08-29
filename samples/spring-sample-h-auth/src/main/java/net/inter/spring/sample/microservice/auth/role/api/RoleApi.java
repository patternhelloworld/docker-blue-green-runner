package net.inter.spring.sample.microservice.auth.role.api;

import net.inter.spring.sample.exception.data.ResourceNotFoundException;
import net.inter.spring.sample.microservice.auth.role.entity.Role;
import net.inter.spring.sample.microservice.auth.role.dao.RoleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("/api/v1")
public class RoleApi {

}