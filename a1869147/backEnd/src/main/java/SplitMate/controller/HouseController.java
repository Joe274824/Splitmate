package SplitMate.controller;

import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/house")
public class HouseController {

    @Autowired
    private JwtUtil jwtUtil; // 用于解析token
    @Autowired
    private UserService userService; // 用于查询用户信息
    @Autowired
    private HouseService houseService; // 用于查询租客信息


    @PostMapping
    public void addHouse(@RequestBody House house) {
        houseService.addHouse(house);
    }

    @PutMapping
    public void updateHouse(@RequestBody House house) {
        houseService.updateHouse(house);
    }

    @DeleteMapping("/{houseId}")
    public void deleteHouse(@PathVariable int houseId) {
        houseService.deleteHouse(houseId);
    }

    @GetMapping("/{houseId}")
    public House getHouseById(@PathVariable int houseId) {
        return houseService.getHouseById(houseId);
    }

    @GetMapping
    public List<House> getAllHouses() {
        return houseService.getAllHouses();
    }

    @GetMapping("/{status}")
    public List<House> getHousesByStatus(@PathVariable int status) {
        return houseService.getHousesByStatus(status);
    }

    @GetMapping("/tenants")
    public ResponseEntity<List<User>> getAllTenants(HttpServletRequest request) {
        // 从请求头中获取token
        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(null);
        }

        // 解析token获取用户名
        String username = jwtUtil.extractUsername(token.substring(7));
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(null);
        }

        // 查询用户信息
        User user = userService.getUserByUsername(username);
        if (user == null || user.getUserType() != 1) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(null);
        }

        // 查询房屋的所有租客
        HouseTenant houseIdByTenantId = houseService.getHouseIdByTenantId(user.getId().intValue());
        int houseId = houseIdByTenantId.getHouseId();
        List<HouseTenant> houseTenant = houseService.getHouseTenantByHouseId(houseId);
        if (houseTenant.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NO_CONTENT).body(null);
        }
        List<User> tenants = new ArrayList<>();
        for (HouseTenant tenant : houseTenant) {
            tenants.add(userService.getUserById((long) tenant.getUserId()));
        }
        return ResponseEntity.ok(tenants);
    }


}

