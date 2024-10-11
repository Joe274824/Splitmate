package SplitMate.domain;

import javax.persistence.*;

@Entity
public class Device {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private int power;

    private String category;

    private String BLEAddress;

    public String getBLEAddress() {
        return BLEAddress;
    }

    public void setBLEAddress(String BLEAddress) {
        this.BLEAddress = BLEAddress;
    }
// Getters and Setters

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getPower() {
        return power;
    }

    public void setPower(int power) {
        this.power = power;
    }
}
