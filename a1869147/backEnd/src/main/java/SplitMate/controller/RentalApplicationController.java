package SplitMate.controller;

import SplitMate.domain.House;
import SplitMate.domain.RentalApplication;
import SplitMate.domain.RentalApplicationWithUserDTO;
import SplitMate.domain.User;
import SplitMate.mapper.HouseTenantMapper;
import SplitMate.service.HouseService;
import SplitMate.service.RentalApplicationService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/application")
public class RentalApplicationController {

    @Autowired
    private RentalApplicationService rentalApplicationService;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private HouseService houseService;
    @Autowired
    private HouseTenantMapper houseTenantMapper;

    @PostMapping("/submit")
    public ResponseEntity<String> submitApplication(@RequestParam Long userId, @RequestParam Long houseId) {
        boolean success = rentalApplicationService.submitApplication(userId, houseId);
        if (success) {
            return ResponseEntity.ok("Application submit successful");
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Application submit failed");
        }
    }

    @ApiOperation(value = "0: 待审批, 1: 已批准, 2: 已拒绝")
    @GetMapping("/house/{houseID}")
    public ResponseEntity<?> getRentalApplicationsByHouseID(@PathVariable Long houseID,
                                                            HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        String jwtToken = token.substring(7);
        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        if (user.getUserType() != 1) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User is not LandLord");
        }
        List<RentalApplicationWithUserDTO> result = new ArrayList<>();
        List<RentalApplication> applications = rentalApplicationService.getPendingApplications(houseID);
        if (!applications.isEmpty()) {
            for (RentalApplication application : applications) {
                User user1 = userService.getUserById(application.getUserId());
                RentalApplicationWithUserDTO rentalApplicationWithUserDTO = new RentalApplicationWithUserDTO(application, user1);
                result.add(rentalApplicationWithUserDTO);
            }
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("There's no pending applications for the house");
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{ApplicationId}")
    public ResponseEntity<?> getRentalApplicationById(@PathVariable Long ApplicationId) {
        return ResponseEntity.ok(rentalApplicationService.getApplicationById(ApplicationId));
    }

    @PostMapping
    public ResponseEntity updateRentalApplication(@RequestBody RentalApplication rentalApplication) {
        if (rentalApplication.getStatus() == 1) {
            rentalApplicationService.updateApplicationStatus(rentalApplication.getId(), rentalApplication.getStatus());
            houseTenantMapper.insertHouseTenant(rentalApplication.getHouseId(), rentalApplication.getUserId());
            return ResponseEntity.ok(HttpStatus.OK);
        } else if (rentalApplication.getStatus() == 2) {
            rentalApplicationService.updateApplicationStatus(rentalApplication.getId(), rentalApplication.getStatus());
            return ResponseEntity.ok(HttpStatus.OK);
        } else {
            rentalApplicationService.updateApplicationStatus(rentalApplication.getId(), rentalApplication.getStatus());
        }
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Rental Application Update failed");
    }
}
