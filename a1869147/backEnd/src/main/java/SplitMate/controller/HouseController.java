package SplitMate.controller;

import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.mapper.HouseMapper;
import SplitMate.mapper.HouseTenantMapper;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/house")
public class HouseController {

    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private UserService userService; // 用于查询用户信息
    @Autowired
    private HouseService houseService; // 用于查询租客信息

    @Autowired
    private HouseTenantMapper houseTenantMapper;

    @PostMapping
    public ResponseEntity addHouse(@RequestBody House house) {
        house.setHouseStatus(1);
        houseService.addHouse(house);
        List<House> houseIdByLandlordId = houseService.getHouseIdByLandlordId((long) house.getLandlordId());
        House house1 = houseIdByLandlordId.get(houseIdByLandlordId.size() - 1);
        houseTenantMapper.insertHouseTenant((long) house1.getHouseId(), (long) house.getLandlordId());
        return ResponseEntity.ok(HttpStatus.ACCEPTED);
    }

    @PostMapping("/uploadHP")
    public ResponseEntity uploadHP(@RequestParam("file") MultipartFile file,
                                   @RequestParam("houseId") int houseId) throws IOException {
        try {
            houseService.uploadHousePhoto(file, houseId);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
        return ResponseEntity.ok(HttpStatus.ACCEPTED);
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

    @GetMapping("/searchByLLN")
    public List<House> getHousesByLandLordName(@RequestParam String name) {
        return houseService.getHousesByLandLordName(name);
    }

    @GetMapping("/houses")
    public ResponseEntity<List<House>> getHousesByLandLord(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String username = jwtUtil.extractUsername(token.substring(7));
        User user = userService.getUserByUsername(username);
        if (user.getUserType() != 1) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(houseService.getHouseIdByLandlordId(user.getId()));
    }

    @GetMapping("/tenants/{houseId}")
    public ResponseEntity<List<User>> getAllTenants(@PathVariable int houseId, HttpServletRequest request) {
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


    @GetMapping("/photo/{houseId}")
    public ResponseEntity<Resource> downloadHousePhoto(@PathVariable int houseId) {
        try {
            Resource photo = houseService.downloadHousePhoto(houseId);
            return ResponseEntity.ok(photo);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}

