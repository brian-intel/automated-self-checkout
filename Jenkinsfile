pipeline {
    agent { label 'docker' }
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '30'))
    }
    stages {
        stage('Scans') {
            parallel {
                stage('Static code scan') {
                    environment {
                        PROJECT_NAME = 'Video Analytics POS System Rapid Prototype'
                        SCANNERS = 'protex'
                    }
                    steps {
                        rbheStaticCodeScan()
                    }
                }
            }
        }
    }
}
