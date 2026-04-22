package com.labmanagement;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.labmanagement.mapper")
public class LabManagementApplication {

    public static void main(String[] args) {
        SpringApplication.run(LabManagementApplication.class, args);
        System.out.println("====================================");
        System.out.println("实验室管理系统启动成功！");
        System.out.println("访问地址: http://localhost:8080");
        System.out.println("====================================");
    }
}
