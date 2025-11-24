pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                // 拉取代码
                git branch: 'main', url: 'https://github.com/xueyy-999/demo-devops-app.git'
            }
        }
        
        stage('Build & Push') {
            steps {
                script {
                    // 定义镜像名称
                    def imageName = "192.168.76.141:5000/library/demo-app:${BUILD_NUMBER}"
                    
                    // 构建镜像
                    sh "docker build -t ${imageName} ."
                    
                    // 登录 Harbor (使用你设置的密码)
                    sh "docker login -u admin -p Harbor12345 192.168.76.141:5000"
                    
                    // 推送镜像
                    sh "docker push ${imageName}"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                script {
                    // 替换 deploy.yaml 中的镜像占位符
                    sh "sed -i 's|IMAGE_PLACEHOLDER|192.168.76.141:5000/library/demo-app:${BUILD_NUMBER}|g' deploy.yaml"
                    
                    // 部署到 K8s
                    sh "kubectl apply -f deploy.yaml"
                }
            }
        }
    }
}
