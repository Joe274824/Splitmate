package SplitMate.domain;

import java.sql.Timestamp;

public class Bluetooth {
    private String macAddress;
    private String username;
    private Timestamp createTime;
    private Timestamp lastConnectedTime;

    // Getters and Setters
    public String getMacAddress() {
        return macAddress;
    }

    public void setMacAddress(String macAddress) {
        this.macAddress = macAddress;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public Timestamp getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Timestamp createTime) {
        this.createTime = createTime;
    }

    public Timestamp getLastConnectedTime() {
        return lastConnectedTime;
    }

    public void setLastConnectedTime(Timestamp lastConnectedTime) {
        this.lastConnectedTime = lastConnectedTime;
    }
}
