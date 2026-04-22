pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'lab-management-system'
        DOCKER_REGISTRY = 'registry.example.com'
    }
    
    stages {
        stage('代码检出') {
            steps {
                echo '📥 检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }
        
        stage('后端构建') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-11'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                echo '🔨 构建后端项目...'
                sh '''
                    cd backend
                    mvn clean package -DskipTests
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'backend/target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('前端构建') {
            agent {
                docker {
                    image 'node:18-alpine'
                }
            }
            steps {
                echo '🔨 构建前端项目...'
                sh '''
                    cd frontend
                    npm install
                    npm run build
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'frontend/dist/**/*', fingerprint: true
                }
            }
        }
        
        stage('Docker镜像构建') {
            steps {
                echo '🐳 构建Docker镜像...'
                sh '''
                    docker-compose build
                '''
            }
        }
        
        stage('部署服务') {
            steps {
                echo '🚀 部署服务...'
                sh '''
                    docker-compose down --remove-orphans || true
                    docker-compose up -d
                '''
            }
        }
        
        stage('健康检查') {
            steps {
                echo '🏥 检查服务健康状态...'
                sh '''
                    echo "等待服务启动..."
                    sleep 60
                    
                    # 检查后端健康
                    for i in {1..30}; do
                        if curl -sf http://localhost:8081/api/actuator/health; then
                            echo "后端服务健康检查通过"
                            break
                        fi
                        echo "等待后端服务... ($i/30)"
                        sleep 5
                    done
                    
                    # 检查前端
                    if curl -sf http://localhost:80; then
                        echo "前端服务健康检查通过"
                    fi
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline执行成功！'
            echo """
            ========================================
            部署完成！
            ========================================
            访问地址:
              前端页面: http://192.168.3.55
              后端API:  http://192.168.3.55:8081/api
            默认账号:
              管理员: admin / admin123
            ========================================
            """
        }
        
        failure {
            echo '❌ Pipeline执行失败！'
            sh 'docker-compose logs || true'
        }
        
        always {
            echo '🧹 清理工作空间...'
            dir(env.WORKSPACE) {
                deleteDir()
            }
        }
    }
}
