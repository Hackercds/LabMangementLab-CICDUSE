package com.labmanagement.common.backup;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 数据备份组件
 */
@Slf4j
@Component
public class BackupComponent {

    @Autowired
    private DataSource dataSource;

    @Value("${backup.path:./backups}")
    private String backupPath;

    @Value("${backup.retention-days:7}")
    private int retentionDays;

    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyyMMdd_HHmmss");

    /**
     * 定时备份（每天凌晨2点执行）
     */
    @Scheduled(cron = "0 0 2 * * ?")
    public void scheduledBackup() {
        log.info("开始定时备份数据库...");
        backup();
    }

    /**
     * 手动备份
     */
    public String backup() {
        try {
            Path backupDir = Paths.get(backupPath);
            if (!Files.exists(backupDir)) {
                Files.createDirectories(backupDir);
            }

            String fileName = "backup_" + DATE_FORMAT.format(new Date()) + ".sql";
            Path backupFile = backupDir.resolve(fileName);

            ProcessBuilder pb = new ProcessBuilder(
                    "mysqldump",
                    "-h" + getDatabaseHost(),
                    "-P" + getDatabasePort(),
                    "-u" + getDatabaseUsername(),
                    "-p" + getDatabasePassword(),
                    "--single-transaction",
                    "--routines",
                    "--triggers",
                    getDatabaseName()
            );

            pb.redirectOutput(backupFile.toFile());
            pb.redirectErrorStream(true);

            Process process = pb.start();
            int exitCode = process.waitFor();

            if (exitCode == 0) {
                log.info("数据库备份成功: {}", backupFile);
                cleanOldBackups();
                return backupFile.toString();
            } else {
                log.error("数据库备份失败，退出码: {}", exitCode);
                throw new RuntimeException("数据库备份失败");
            }
        } catch (Exception e) {
            log.error("数据库备份异常: {}", e.getMessage(), e);
            throw new RuntimeException("数据库备份失败", e);
        }
    }

    /**
     * 恢复数据库
     */
    public void restore(String backupFile) {
        try {
            Path file = Paths.get(backupFile);
            if (!Files.exists(file)) {
                throw new FileNotFoundException("备份文件不存在: " + backupFile);
            }

            ProcessBuilder pb = new ProcessBuilder(
                    "mysql",
                    "-h" + getDatabaseHost(),
                    "-P" + getDatabasePort(),
                    "-u" + getDatabaseUsername(),
                    "-p" + getDatabasePassword(),
                    getDatabaseName()
            );

            pb.redirectInput(file.toFile());
            pb.redirectErrorStream(true);

            Process process = pb.start();
            int exitCode = process.waitFor();

            if (exitCode == 0) {
                log.info("数据库恢复成功: {}", backupFile);
            } else {
                log.error("数据库恢复失败，退出码: {}", exitCode);
                throw new RuntimeException("数据库恢复失败");
            }
        } catch (Exception e) {
            log.error("数据库恢复异常: {}", e.getMessage(), e);
            throw new RuntimeException("数据库恢复失败", e);
        }
    }

    /**
     * 清理旧备份
     */
    private void cleanOldBackups() {
        try {
            Path backupDir = Paths.get(backupPath);
            long cutoffTime = System.currentTimeMillis() - (retentionDays * 24L * 60 * 60 * 1000);

            Files.list(backupDir)
                    .filter(path -> path.getFileName().toString().startsWith("backup_"))
                    .filter(path -> {
                        try {
                            return Files.getLastModifiedTime(path).toMillis() < cutoffTime;
                        } catch (IOException e) {
                            return false;
                        }
                    })
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                            log.info("删除旧备份: {}", path);
                        } catch (IOException e) {
                            log.error("删除旧备份失败: {}", path, e);
                        }
                    });
        } catch (Exception e) {
            log.error("清理旧备份失败: {}", e.getMessage(), e);
        }
    }

    private String getDatabaseHost() {
        return "localhost";
    }

    private String getDatabasePort() {
        return "3306";
    }

    private String getDatabaseName() {
        return "lab_management";
    }

    private String getDatabaseUsername() {
        return "root";
    }

    private String getDatabasePassword() {
        return "";
    }
}
