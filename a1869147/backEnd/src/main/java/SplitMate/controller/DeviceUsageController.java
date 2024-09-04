package SplitMate.controller;

import SplitMate.domain.DeviceUsage;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.service.DeviceUsageService;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import com.alibaba.fastjson.JSONArray;
import io.swagger.annotations.ApiParam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/deviceUsages")
public class DeviceUsageController {

    @Autowired
    private DeviceUsageService deviceUsageService;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private HouseService houseService;

    @GetMapping
    public List<DeviceUsage> getAllDeviceUsages() {
        return deviceUsageService.getAllDeviceUsages();
    }

    @GetMapping("/{id}")
    public DeviceUsage getDeviceUsageById(@PathVariable Long id) {
        return deviceUsageService.getDeviceUsageById(id);
    }

    @PostMapping
    public void createDeviceUsage(@RequestBody DeviceUsage deviceUsage) {
        deviceUsageService.createDeviceUsage(deviceUsage);
    }

    @GetMapping("/username")
    public void getDeviceUsageByUserID(HttpServletRequest request) throws IOException {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        WebSocketServer.sendInfo(JSONArray.toJSONString(deviceUsageService.getDeviceUsageByUsername(username)), user.getId());
    }

    @PutMapping("/{id}")
    public void updateDeviceUsage(@PathVariable Long id, @RequestBody DeviceUsage deviceUsage) {
        deviceUsage.setId(id);
        deviceUsageService.updateDeviceUsage(deviceUsage);
    }

    @DeleteMapping("/{id}")
    public void deleteDeviceUsage(@PathVariable Long id) {
        deviceUsageService.deleteDeviceUsage(id);
    }

    @GetMapping("/userOneMonth")
    public List<DeviceUsage> getDeviceUsageOneMonth(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        return deviceUsageService.getDeviceUsageOneMonth(user.getId());
    }

    @GetMapping("/AllUsageForMT")
    public List<DeviceUsage> getAllDeviceUsageForMT(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        List<HouseTenant> tenants = houseService.getHouseTenantByHouseId(houseService.getHouseIdByTenantId(user.getId().intValue()).getUserId());
        List<DeviceUsage> AllUsage = new ArrayList<>();
        for (HouseTenant tenant : tenants) {
            AllUsage.add(deviceUsageService.getDeviceUsageById(tenant.getId()));
        }
        return AllUsage;
    }

}