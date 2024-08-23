package SplitMate.mapper;

import SplitMate.domain.Bill;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface BillMapper {

    void insertBill(Bill bill);

    Bill getBillById(Long id);

    List<Bill> getBillsByUserId(Long userId);

    List<Bill> getAllBills();

    void deleteBillById(Long id);
}
