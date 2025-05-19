package SplitMate.mapper;

import SplitMate.domain.PaymentRecord;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PaymentRecordMapper {

    void insertPaymentRecord(PaymentRecord paymentRecord);


    PaymentRecord getPaymentRecordById(int paymentId);


    void updatePaymentRecord(PaymentRecord paymentRecord);


    void deletePaymentRecord(int paymentId);

    List<PaymentRecord> getPaymentRecordByUserIdAndBillMouth(Integer userId);

    List<PaymentRecord> getPaymentRecordByHouseId(Integer houseId);

    List<PaymentRecord> getPaymentHistory(Integer id);
}
