package SplitMate.controller;

import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.domain.User;
import SplitMate.service.HouseService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserService userService;

    @Autowired
    private HouseService houseService;


    @ApiOperation(value = "Login",notes = "response userType: 1-main tenant  0-ordinary tenant")
    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody AuthenticationRequest authenticationRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(authenticationRequest.getUsername(), authenticationRequest.getPassword()));
            UserDetails userDetails = userDetailsService.loadUserByUsername(authenticationRequest.getUsername());
            String jwt = jwtUtil.generateToken(userDetails.getUsername());
            User user = userService.getUserByUsername(userDetails.getUsername());
            List<Integer> house = new ArrayList<>();
            if (user.getUserType() == 1) {
                List<House> houses = houseService.getHouseIdByLandlordId(user.getId());
                if (houses != null) {
                    houses.forEach(h -> {
                        house.add(h.getHouseId());
                    });
                }
            } else {
                HouseTenant houseTenant = houseService.getHouseIdByTenantId(user.getId().intValue());
                if (houseTenant != null) {
                    house.add(houseTenant.getHouseId());
                }
            }
            Map<String, String> response = new HashMap<>();
            response.put("token", jwt);
            response.put("usertype", user.getUserType() + "");
            response.put("houseId", house.isEmpty() ? "null" : house + "");
            if (!Objects.equals(user.getUserPhoneId(), authenticationRequest.getUserPhoneID())) {
                response.put("userPhoneIdCheck", "false");
            } else {
                response.put("userPhoneIdCheck", "true");
            }
            return ResponseEntity.ok(response.toString());
        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Login failed: " + e.getMessage());
        }
    }

}
