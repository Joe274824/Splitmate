package SplitMate.controller;

import SplitMate.domain.PaymentRecord;
import SplitMate.service.PaymentRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/payment-records")
public class PaymentRecordController {

    @Autowired
    private PaymentRecordService paymentRecordService;

//    @PostMapping
//    public String addPaymentRecord(@RequestBody PaymentRecord paymentRecord) {
//        paymentRecordService.addPaymentRecord(paymentRecord);
//        return "Payment record added successfully";
//    }

    @GetMapping
    public List<PaymentRecord> getPaymentRecords(@RequestParam Integer userId,
                                                 @RequestParam(required = false) String billMonth) {
        return paymentRecordService.getPaymentRecordByUserIdAndBillMouth(userId, billMonth);
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
}
