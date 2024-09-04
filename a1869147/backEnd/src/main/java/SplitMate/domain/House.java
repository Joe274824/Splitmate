package SplitMate.domain;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;

@Entity
public class House {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int houseId;

    private byte houseStatus;
    private int landlordId;
    private int houseCapacity;
    private int currentTenants;
    private Integer availableTenants; // This field will be auto-calculated

    // Getters and Setters
    public int getHouseId() {
        return houseId;
    }

    public void setHouseId(int houseId) {
        this.houseId = houseId;
    }

    public byte getHouseStatus() {
        return houseStatus;
    }

    public void setHouseStatus(byte houseStatus) {
        this.houseStatus = houseStatus;
    }

    public int getLandlordId() {
        return landlordId;
    }

    public void setLandlordId(int landlordId) {
        this.landlordId = landlordId;
    }

    public int getHouseCapacity() {
        return houseCapacity;
    }

    public void setHouseCapacity(int houseCapacity) {
        this.houseCapacity = houseCapacity;
    }

    public int getCurrentTenants() {
        return currentTenants;
    }

    public void setCurrentTenants(int currentTenants) {
        this.currentTenants = currentTenants;
    }

    public Integer getAvailableTenants() {
        return availableTenants;
    }

    public void setAvailableTenants(Integer availableTenants) {
        this.availableTenants = availableTenants;
    }
}

