pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/xueyy-999/demo-devops-app.git'
            }
        }
        
        stage('Build & Push') {
            steps {
                script {
                    def imageName = "192.168.76.141:5000/library/demo-app:${BUILD_NUMBER}"
                    sh "docker build -t ${imageName} ."
                    sh "docker login -u admin -p Harbor12345 192.168.76.141:5000"
                    sh "docker push ${imageName}"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                script {
                    def deployImage = "192.168.76.141:5000/library/demo-app:${BUILD_NUMBER}"
                    
                    // 动态生成 k8s.yaml，确保镜像地址正确
                    sh """
cat <<EOF > k8s.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: ${deployImage}
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
spec:
  selector:
    app: demo-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
EOF
"""
                    // 打印内容以便调试
                    sh "cat k8s.yaml"
                    
                    // 执行部署
                    sh "kubectl apply -f k8s.yaml"
                    
                    // 强制重启以应用新镜像 (如果 Deployment 已存在)
                    sh "kubectl rollout restart deployment demo-app || true"
                }
            }
        }
    }
}
