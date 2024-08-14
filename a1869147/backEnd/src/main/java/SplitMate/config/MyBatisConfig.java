package SplitMate.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("SplitMate.mapper")
public class MyBatisConfig {
}