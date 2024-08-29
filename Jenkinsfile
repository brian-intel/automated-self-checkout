pipeline {
    agent {
         node {
            label 'aws-ec2'
         }
    }
    stages {
        stage('Build Helm Chart') {
            steps {
                helmChartBuild()
            }
        }
    }
}