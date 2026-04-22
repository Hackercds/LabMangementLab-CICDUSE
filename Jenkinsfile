pipeline {
    agent any
    
    environment {
        // 项目配置
        PROJECT_NAME = 'lab-management-system'
        BACKEND_DIR = 'backend'
        FRONTEND_DIR = 'frontend'
        TESTS_DIR = 'tests'
        
        // 服务器配置
        DEPLOY_SERVER = credentials('deploy-server')
        DEPLOY_USER = credentials('deploy-user')
        DEPLOY_PATH = '/opt/lab-management'
        
        // 数据库配置
        DB_HOST = credentials('db-host')
        DB_PORT = '3306'
        DB_NAME = 'lab_management'
        DB_USER = credentials('db-user')
        DB_PASSWORD = credentials('db-password')
        
        // Docker配置
        DOCKER_REGISTRY = 'registry.example.com'
        DOCKER_IMAGE_BACKEND = "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend"
        DOCKER_IMAGE_FRONTEND = "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend"
    }
    
    stages {
        stage('代码检出') {
            steps {
                echo '📥 检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }
        
        stage('环境准备') {
            steps {
                echo '🔧 准备构建环境...'
                sh '''
                    # 检查Java版本
                    java -version
                    
                    # 检查Node.js版本
                    node --version
                    npm --version
                    
                    # 检查Python版本
                    python --version
                    pip --version
                '''
            }
        }
        
        stage('后端构建') {
            steps {
                echo '🔨 构建后端项目...'
                dir(BACKEND_DIR) {
                    sh '''
                        # 清理并编译
                        mvn clean package -DskipTests
                        
                        # 检查构建结果
                        if [ ! -f "target/*.jar" ]; then
                            echo "后端构建失败"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('前端构建') {
            steps {
                echo '🔨 构建前端项目...'
                dir(FRONTEND_DIR) {
                    sh '''
                        # 安装依赖
                        npm install
                        
                        # 构建生产版本
                        npm run build
                        
                        # 检查构建结果
                        if [ ! -d "dist" ]; then
                            echo "前端构建失败"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('后端单元测试') {
            steps {
                echo '🧪 运行后端单元测试...'
                dir(BACKEND_DIR) {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit "${BACKEND_DIR}/target/surefire-reports/*.xml"
                }
            }
        }
        
        stage('代码质量检查') {
            parallel {
                stage('后端代码检查') {
                    steps {
                        echo '🔍 后端代码质量检查...'
                        dir(BACKEND_DIR) {
                            sh 'mvn checkstyle:check || true'
                        }
                    }
                }
                stage('前端代码检查') {
                    steps {
                        echo '🔍 前端代码质量检查...'
                        dir(FRONTEND_DIR) {
                            sh 'npm run lint || true'
                        }
                    }
                }
            }
        }
        
        stage('Docker镜像构建') {
            steps {
                echo '🐳 构建Docker镜像...'
                script {
                    // 构建后端镜像
                    dir(BACKEND_DIR) {
                        sh """
                            docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .
                            docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest
                        """
                    }
                    
                    // 构建前端镜像
                    dir(FRONTEND_DIR) {
                        sh """
                            docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .
                            docker tag ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_FRONTEND}:latest
                        """
                    }
                }
            }
        }
        
        stage('Docker镜像推送') {
            when {
                branch 'main'
            }
            steps {
                echo '📤 推送Docker镜像...'
                script {
                    sh """
                        docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE_BACKEND}:latest
                        docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE_FRONTEND}:latest
                    """
                }
            }
        }
        
        stage('部署到测试环境') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 部署到测试环境...'
                script {
                    sh """
                        # SSH部署到测试服务器
                        ssh ${DEPLOY_USER}@${DEPLOY_SERVER} << EOF
                            cd ${DEPLOY_PATH}
                            
                            # 拉取最新镜像
                            docker-compose pull
                            
                            # 重启服务
                            docker-compose down
                            docker-compose up -d
                            
                            # 等待服务启动
                            sleep 30
                            
                            # 检查服务状态
                            docker-compose ps
                        EOF
                    """
                }
            }
        }
        
        stage('部署到生产环境') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 部署到生产环境...'
                script {
                    // 使用蓝绿部署策略
                    sh """
                        ssh ${DEPLOY_USER}@${DEPLOY_SERVER} << EOF
                            cd ${DEPLOY_PATH}
                            
                            # 备份当前版本
                            ./scripts/backup.sh
                            
                            # 拉取最新镜像
                            docker-compose -f docker-compose.prod.yml pull
                            
                            # 执行蓝绿部署
                            ./scripts/blue-green-deploy.sh
                            
                            # 等待服务启动
                            sleep 30
                            
                            # 健康检查
                            ./scripts/health-check.sh
                        EOF
                    """
                }
            }
        }
        
        stage('冒烟测试') {
            steps {
                echo '🧪 运行冒烟测试...'
                dir(TESTS_DIR) {
                    sh '''
                        # 安装测试依赖
                        pip install -r requirements.txt
                        
                        # 运行冒烟测试
                        python run_tests.py smoke
                        
                        # 检查测试结果
                        if [ $? -ne 0 ]; then
                            echo "冒烟测试失败，回滚部署"
                            exit 1
                        fi
                    '''
                }
            }
            post {
                always {
                    // 发布Allure测试报告
                    allure includeProperties: false, jdk: '', results: [[path: "${TESTS_DIR}/reports/allure-results"]]
                }
            }
        }
        
        stage('API自动化测试') {
            when {
                branch 'develop'
            }
            steps {
                echo '🧪 运行API自动化测试...'
                dir(TESTS_DIR) {
                    sh 'python run_tests.py full'
                }
            }
            post {
                always {
                    allure includeProperties: false, jdk: '', results: [[path: "${TESTS_DIR}/reports/allure-results"]]
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline执行成功！'
            script {
                // 发送成功通知
                emailext(
                    subject: "✅ ${PROJECT_NAME} - 构建成功 #${BUILD_NUMBER}",
                    body: """
                        <h2>构建成功</h2>
                        <p><strong>项目:</strong> ${PROJECT_NAME}</p>
                        <p><strong>构建号:</strong> #${BUILD_NUMBER}</p>
                        <p><strong>分支:</strong> ${BRANCH_NAME}</p>
                        <p><strong>提交:</strong> ${env.GIT_COMMIT}</p>
                        <p><a href="${BUILD_URL}">查看构建详情</a></p>
                    """,
                    to: 'team@example.com'
                )
            }
        }
        
        failure {
            echo '❌ Pipeline执行失败！'
            script {
                // 发送失败通知
                emailext(
                    subject: "❌ ${PROJECT_NAME} - 构建失败 #${BUILD_NUMBER}",
                    body: """
                        <h2>构建失败</h2>
                        <p><strong>项目:</strong> ${PROJECT_NAME}</p>
                        <p><strong>构建号:</strong> #${BUILD_NUMBER}</p>
                        <p><strong>分支:</strong> ${BRANCH_NAME}</p>
                        <p><strong>提交:</strong> ${env.GIT_COMMIT}</p>
                        <p><a href="${BUILD_URL}console">查看控制台日志</a></p>
                    """,
                    to: 'team@example.com'
                )
            }
        }
        
        always {
            // 清理工作空间
            cleanWs()
        }
    }
}
