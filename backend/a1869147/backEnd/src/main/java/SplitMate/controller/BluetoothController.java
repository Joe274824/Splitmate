package SplitMate.controller;

import SplitMate.domain.Bluetooth;
import SplitMate.service.BluetoothService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/bluetooth")
public class BluetoothController {

    @Autowired
    private BluetoothService bluetoothService;

    @PostMapping("/add")
    public String addBluetooth(@RequestBody Bluetooth bluetooth) {
        bluetoothService.addBluetooth(bluetooth);
        return "Bluetooth device added successfully!";
    }

    @GetMapping("/{macAddress}")
    public Bluetooth getBluetoothByMacAddress(@PathVariable String macAddress) {
        return bluetoothService.getBluetoothByMacAddress(macAddress);
    }

    @GetMapping("/user/{username}")
    public List<Bluetooth> getBluetoothByUsername(@PathVariable String username) {
        return bluetoothService.getBluetoothByUsername(username);
    }

    @PutMapping("/update/{macAddress}")
    public String updateLastConnectedTime(@PathVariable String macAddress, @RequestBody Bluetooth bluetooth) {
        bluetoothService.updateLastConnectedTime(macAddress, bluetooth);
        return "Last connected time updated!";
    }

    @DeleteMapping("/delete/{macAddress}")
    public String deleteBluetooth(@PathVariable String macAddress) {
        bluetoothService.deleteBluetooth(macAddress);
        return "Bluetooth device deleted!";
    }

    @PostMapping("/usage")
    public ResponseEntity<String> usage(@RequestParam("MACAddress") String MACAddress, @RequestParam("uuid") String BLEAddress) {
        boolean addUsage = bluetoothService.addUsage(MACAddress, BLEAddress);
        if (addUsage) {
            return ResponseEntity.ok("successfully add user usage");
        }
        return ResponseEntity.status(HttpStatus.CONFLICT).body("unsuccessfully add user usage");
    }
}
