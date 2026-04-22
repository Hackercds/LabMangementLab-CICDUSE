@echo off
REM 实验室管理系统 - Windows部署配置文件
REM 支持多语言项目配置

REM ============================================
REM 项目基础配置
REM ============================================
set PROJECT_NAME=lab-management-system
set PROJECT_ROOT=%~dp0..

REM 日志和PID目录
set LOG_DIR=%PROJECT_ROOT%\logs
set PID_DIR=%PROJECT_ROOT%\pids

REM ============================================
REM Java 服务配置
REM ============================================
set JAVA_ENABLED=true
set JAVA_SERVICE_NAME=backend
set JAVA_PORT=8081
set JAVA_JAR_PATH=%PROJECT_ROOT%\backend\target\lab-management-backend.jar
set JAVA_SOURCE_PATH=%PROJECT_ROOT%\backend
set JAVA_JVM_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC
set JAVA_SPRING_PROFILE=dev
set JAVA_MAVEN_OPTS=-DskipTests

REM ============================================
REM Python 服务配置
REM ============================================
set PYTHON_ENABLED=false
set PYTHON_SERVICE_NAME=python-service
set PYTHON_PORT=5000
set PYTHON_SCRIPT_PATH=%PROJECT_ROOT%\python-service\app.py
set PYTHON_VENV_PATH=%PROJECT_ROOT%\python-service\venv
set PYTHON_REQUIREMENTS=%PROJECT_ROOT%\python-service\requirements.txt

REM ============================================
REM Golang 服务配置
REM ============================================
set GOLANG_ENABLED=false
set GOLANG_SERVICE_NAME=golang-service
set GOLANG_PORT=8000
set GOLANG_BINARY_PATH=%PROJECT_ROOT%\golang-service\bin\server.exe
set GOLANG_SOURCE_PATH=%PROJECT_ROOT%\golang-service

REM ============================================
REM 前端服务配置
REM ============================================
set FRONTEND_ENABLED=true
set FRONTEND_SERVICE_NAME=frontend
set FRONTEND_PORT=3000
set FRONTEND_SOURCE_PATH=%PROJECT_ROOT%\frontend
set FRONTEND_BUILD_COMMAND=npm run build
set FRONTEND_DEV_COMMAND=npm run dev

REM ============================================
REM 数据库配置
REM ============================================
set DATABASE_HOST=localhost
set DATABASE_PORT=3306
set DATABASE_NAME=lab_management
set DATABASE_USER=root
set DATABASE_PASSWORD=root123456

REM ============================================
REM Redis 配置
REM ============================================
set REDIS_HOST=localhost
set REDIS_PORT=6379
set REDIS_PASSWORD=

REM ============================================
REM 监控配置
REM ============================================
set MONITOR_ENABLED=true
set MONITOR_INTERVAL=60
set MONITOR_LOG=%LOG_DIR%\monitor.log

REM 健康检查配置
set HEALTH_CHECK_ENABLED=true
set HEALTH_CHECK_INTERVAL=30
set HEALTH_CHECK_TIMEOUT=10

REM ============================================
REM 自拉起配置
REM ============================================
set DAEMON_ENABLED=true
set DAEMON_CHECK_INTERVAL=30
set DAEMON_MAX_RESTART_COUNT=5
set DAEMON_RESTART_DELAY=10

REM ============================================
REM 备份配置
REM ============================================
set BACKUP_ENABLED=true
set BACKUP_DIR=%PROJECT_ROOT%\backups
set BACKUP_RETENTION_DAYS=7

REM ============================================
REM 创建必要目录
REM ============================================
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%PID_DIR%" mkdir "%PID_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
