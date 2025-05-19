package SplitMate.controller;

import SplitMate.domain.PaymentRecord;
import SplitMate.domain.User;
import SplitMate.service.PaymentRecordService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/payment-records")
public class PaymentRecordController {

    @Autowired
    private PaymentRecordService paymentRecordService;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private UserService userService;

//    @PostMapping
//    public String addPaymentRecord(@RequestBody PaymentRecord paymentRecord) {
//        paymentRecordService.addPaymentRecord(paymentRecord);
//        return "Payment record added successfully";
//    }

    @GetMapping
    public List<PaymentRecord> getPaymentRecords(@RequestParam Integer userId) {
        return paymentRecordService.getPaymentRecordByUserIdAndBillMouth(userId);
    }

    @GetMapping("/{id}")
    public Optional<PaymentRecord> getPaymentRecordById(@PathVariable("id") int paymentId) {
        return paymentRecordService.getPaymentRecordById(paymentId);
    }

    @PutMapping("/{id}")
    public String updatePaymentRecord(@PathVariable("id") int paymentId, @RequestBody PaymentRecord paymentRecord) {
        paymentRecord.setPaymentId(paymentId);
        paymentRecordService.updatePaymentRecord(paymentRecord);
        return "Payment record updated successfully";
    }

    @DeleteMapping("/{id}")
    public String deletePaymentRecord(@PathVariable("id") int paymentId) {
        paymentRecordService.deletePaymentRecord(paymentId);
        return "Payment record deleted successfully";
    }

    @PostMapping("/houseId")
    public List<PaymentRecord> getPaymentRecordByHouseId(@RequestParam Integer houseId) {
        return paymentRecordService.getPaymentRecordByHouseId(houseId);
    }
}
