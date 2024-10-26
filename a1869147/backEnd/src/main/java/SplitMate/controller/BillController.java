package SplitMate.controller;

import SplitMate.domain.Bill;
import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.service.BillService;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import io.swagger.annotations.ApiParam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@RestController
@RequestMapping("/bills")
public class BillController {

    @Autowired
    private BillService billService;

    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private UserService userService;

    @Autowired
    private HouseService houseService;

    @PostMapping("/upload")
    public ResponseEntity<String> uploadBill(@RequestParam("file") MultipartFile file,
                                             @RequestParam("userId") Long userId,
                                             @RequestParam("houseId") Long houseId,
                                             @RequestParam("billDate") String billDate,
                                             @RequestParam("category") String category,
                                             @RequestParam("billPrice") BigDecimal billPrice) {
        String filename = file.getOriginalFilename();
        if (!Objects.requireNonNull(filename).isEmpty() && !filename.substring(file.getOriginalFilename().lastIndexOf(".")).equalsIgnoreCase("pdf")) {
            ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only allows upload pdf bills");
        }
        // 检查用户是否为主租户
        if (billService.isMainTenant(userId)) {
            try {
                Bill bill = new Bill();
                bill.setUserId(userId);
                bill.setHouseId(houseId);
                bill.setBillDate(billDate);
                bill.setCategory(category);
                bill.setBillPrice(billPrice);
                billService.saveBill(file, bill);
                return ResponseEntity.ok("Bill uploaded successfully");
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("Failed to upload bill: " + e.getMessage());
            }
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only the main tenant can upload bills");
        }
    }

    // 查询所有可下载的账单
    @GetMapping
    public List<Bill> getAllBills(@RequestHeader("Authorization") @ApiParam(required = false) String token) {
        String jwtToken = token.substring(7);
        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        List<Bill> allBills = new ArrayList<>();
        if (user.getUserType() == 1) {
            List<House> houses = houseService.getHouseIdByLandlordId(user.getId());
            for (House house : houses) {
                allBills.addAll(billService.getAllBills((long) house.getHouseId()));
            }
        } else {
            HouseTenant house = houseService.getHouseIdByTenantId(user.getId().intValue());
            allBills.addAll(billService.getAllBills((long) house.getHouseId()));
        }
        return allBills;
    }

    // 下载指定的 PDF 文件
    @GetMapping("/download/{billId}")
    public ResponseEntity<Resource> downloadBill(@PathVariable Long billId) {
        Resource file = billService.loadBillAsResource(billId);
        if (file.exists()) {
            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_PDF)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + file.getFilename() + "\"")
                    .body(file);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/update")
    public ResponseEntity<String> updateBill(@RequestBody Bill bill) {
        try {
            billService.updateBill(bill);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed update bill, please try again.");
        }
        return ResponseEntity.ok("Successfully update bill");
    }

    @PostMapping("/createPaymentRecord")
    public ResponseEntity<String> createPaymentRecord(@RequestParam("billId")Long billId,
                                                      @RequestHeader("Authorization") @ApiParam(required = false)String token) {
        String jwtToken = token.substring(7);
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        if (user.getUserType() != 1) {
            ResponseEntity.status(HttpStatus.CONFLICT).body("Only Landlord can generate payment record");
        }
        Bill bill = billService.getBillById(billId);
        List<HouseTenant> tenants = houseService.getHouseTenantByHouseId(bill.getHouseId().intValue());
        try {
            billService.generatePayment(bill, tenants);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("generate failed:" + e.getMessage());
        }
        return ResponseEntity.ok().body("generate successfully");
    }
}
