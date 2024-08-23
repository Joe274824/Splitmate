package SplitMate.controller;

import SplitMate.domain.Bill;
import SplitMate.service.BillService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


import java.util.List;

@RestController
@RequestMapping("/bills")
public class BillController {

    @Autowired
    private BillService billService;

    @PostMapping("/upload")
    public ResponseEntity<String> uploadBill(@RequestParam("file") MultipartFile file,
                                             @RequestParam("userId") Long userId) {
        // 检查用户是否为主租户
        if (billService.isMainTenant(userId)) {
            try {
                billService.saveBill(file, userId);
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
    public List<Bill> getAllBills() {
        return billService.getAllBills();
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
}
