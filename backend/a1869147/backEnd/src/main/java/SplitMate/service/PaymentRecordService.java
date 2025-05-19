package SplitMate.service;

import SplitMate.domain.PaymentRecord;
import SplitMate.mapper.PaymentRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PaymentRecordService {

    @Autowired
    private PaymentRecordMapper paymentRecordMapper;

    public void addPaymentRecord(PaymentRecord paymentRecord) {
        paymentRecordMapper.insertPaymentRecord(paymentRecord);
    }

    public Optional<PaymentRecord> getPaymentRecordById(int paymentId) {
        return Optional.ofNullable(paymentRecordMapper.getPaymentRecordById(paymentId));
    }

    public void updatePaymentRecord(PaymentRecord paymentRecord) {
        paymentRecordMapper.updatePaymentRecord(paymentRecord);
    }

    public void deletePaymentRecord(int paymentId) {
        paymentRecordMapper.deletePaymentRecord(paymentId);
    }

    public List<PaymentRecord> getPaymentRecordByUserIdAndBillMouth(Integer userId) {
        return paymentRecordMapper.getPaymentRecordByUserIdAndBillMouth(userId);
    }

    public List<PaymentRecord> getPaymentRecordByHouseId(Integer houseId) {
        return paymentRecordMapper.getPaymentRecordByHouseId(houseId);
    }

    public List<PaymentRecord> getPaymentHistory(Integer id) {
        return paymentRecordMapper.getPaymentHistory(id);
    }
}