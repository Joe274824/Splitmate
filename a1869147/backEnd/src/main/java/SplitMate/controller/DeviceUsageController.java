package SplitMate.controller;

import SplitMate.domain.DeviceUsage;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.service.DeviceUsageService;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.time.LocalDate;
import java.time.YearMonth;
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
    public ResponseEntity<?> getDeviceUsageByUserID(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        if (user != null) {
            // 获取设备使用记录并返回
            List<DeviceUsage> deviceUsages = deviceUsageService.getDeviceUsageByUsername(username);
            return ResponseEntity.ok(deviceUsages);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found");
        }
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
    public List<DeviceUsage> getDeviceUsageOneMonth(@RequestParam("year") int year,
                                                    @RequestParam("month") int month,
                                                    HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        // 获取指定月份的第一天和最后一天
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startOfMonth = yearMonth.atDay(1);
        LocalDate endOfMonth = yearMonth.atEndOfMonth();
        return deviceUsageService.getDeviceUsageByMonth(user.getId(), startOfMonth, endOfMonth);
    }

    @GetMapping("/AllUsageForMT")
    public ResponseEntity<?> getAllDeviceUsageForMT(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        if (user.getUserType() != 1) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("User is not permitted");
        }
        List<HouseTenant> tenants = houseService.getHouseTenantByHouseId(houseService.getHouseIdByTenantId(user.getId().intValue()).getUserId());
        List<DeviceUsage> AllUsage = new ArrayList<>();
        for (HouseTenant tenant : tenants) {
            User user1 = userService.getUserById((long) tenant.getUserId());
            List<DeviceUsage> usage = deviceUsageService.getDeviceUsageByUsername(user1.getUsername());
            AllUsage.addAll(usage);
        }
        return ResponseEntity.ok(AllUsage);
    }

}