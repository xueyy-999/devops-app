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
                    sh "docker push 192.168.76.141:5000/library/demo-app:latest"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                script {
                    echo "🚀 Starting Deployment..."
                    def deployImage = "192.168.76.141:5000/library/demo-app:${BUILD_NUMBER}"
                    
                    sh """
cat <<EOF > k8s.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: default
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
  namespace: default
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
                    // 显式指定 kubeconfig 路径，并开启详细日志
                    sh "kubectl apply -f k8s.yaml --kubeconfig=/var/lib/jenkins/.kube/config -v=4"
                    
                    // 强制重启
                    sh "kubectl rollout restart deployment demo-app --namespace=default --kubeconfig=/var/lib/jenkins/.kube/config"
                    
                    echo "✅ Deployment Finished!"
                }
            }
        }
    }
}
