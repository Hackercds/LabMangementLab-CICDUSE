package com.labmanagement;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
@MapperScan("com.labmanagement.mapper")
public class LabManagementApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext ctx = SpringApplication.run(LabManagementApplication.class, args);
        String port = ctx.getEnvironment().getProperty("server.port", "8080");
        String contextPath = ctx.getEnvironment().getProperty("server.servlet.context-path", "");
        System.out.println("====================================");
        System.out.println("实验室管理系统启动成功！");
        System.out.println("访问地址: http://0.0.0.0:" + port + contextPath);
        System.out.println("====================================");
    }
}
