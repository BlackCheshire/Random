def commitId

pipeline {
    agent {
        kubernetes {
            label 'referral-builder'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: tiller
  containers:
  - name: referral-php-fpm-base
    image: dockerreg.test.ru/test/referral-php-fpm-base:latest
    command:
    - cat
    tty: true
    resources:
      limits:
        cpu: 130m
        memory: 166Mi
      requests:
        cpu: 100m
        memory: 128Mi
  - name: js-node
    image: node:8
    command:
    - cat
    tty: true
  - name: docker
    image: docker:18.02
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-socket
    resources:
      limits:
        cpu: 200m
        memory: 200Mi
      requests:
        cpu: 150m
        memory: 150Mi
  - name: kubectl-istio
    image: dockerreg.test.ru/test/istio-kubectl:1.3.2
    command:
    - cat
    tty: true
    resources:
      limits:
        cpu: 200m
        memory: 200Mi
      requests:
        cpu: 150m
        memory: 150Mi
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket
  nodeSelector:
    nodetype: jenkins
  tolerations:
  - key: "constraint"
    operator: "Equal"
    value: "jenkins"
    effect: "NoSchedule"
"""
        }
    }

    environment {
        PROJECTNAME = 'referral'
        NAMESPACE ="'${PROJECTNAME}'-prod"
        REPOSITORY = 'localhost:80'
        SUCCESS_MESSAGE = "Job: ${env.JOB_NAME} with number ${env.BUILD_NUMBER} was successful \n ${env.BUILD_URL}"
        FAILURE_MESSAGE = "Job: ${env.JOB_NAME} with number ${env.BUILD_NUMBER} was failed \n ${env.BUILD_URL}"

        DATABASE_HOST = 'referral-postgresql'
        DATABASE_PORT = '5432'
        SLACK_RECIPIENTS = 'test-notifications'

        COMPOSER_AUTH = credentials('composer_token')
        PRODUCTION_SECRET = credentials('production_secret')
        REFERRAL_DATABASE_PASSWORD = credentials('referral_database_password')
    }

    options {
      timeout(time: 15, unit: 'MINUTES')
      disableConcurrentBuilds()
    }

    stages {

        stage ('Checkout') {
            steps {
                git branch: "${env.BRANCH_NAME}",
                credentialsId: 'k8s_test_github_token',
                url: 'https://github.com/test/referral.git'
                script {
                    commitId = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    currentBuild.description = "${commitId}"
                    echo "${commitId}"
                }
            }
        }

        stage ('Install Composer') {
            steps {
                container ('referral-php-fpm-base') {
                    sh "./bin/composer.phar install --no-interaction"
                }
            }
        }

        stage ('Run Unit tests') {
            steps {
                container ('referral-php-fpm-base') {
                    sh "rm -rf ./var/cache/test"
                    sh "./bin/phpunit -c tests/phpunit.xml --log-junit tests/tests-result.xml"
                    sh "./bin/composer.phar install --no-dev --optimize-autoloader --no-interaction"
                }
            }
            post {
                always {
                    junit 'tests/tests-result.xml'
                }
            }
        }

        stage('Generate API schema') {
                    when {
                        branch 'master'
                    }
                    steps {
                        container ('js-node') {
                            sh "npm i -g raml2html"
                            sh "raml2html ./src/Resources/raml/protected.raml -o ./templates/raml/raml_protected.html.twig"
                            sh "raml2html ./src/Resources/raml/internal.raml -o ./templates/raml/raml_internal.html.twig"
                        }
                    }
                }

        stage ('Build and push docker image') {
            when {
              branch 'master'
            }
            steps {
                container ('docker') {
                    sh "docker build -f build/prod/php-fpm/Dockerfile -t test/referral-php-fpm-prod:'${commitId}' ./"
                    sh "docker tag test/referral-php-fpm-prod:'${commitId}' '${REPOSITORY}'/test/referral-php-fpm-prod:'${commitId}'"
                    sh "docker push '${REPOSITORY}'/test/referral-php-fpm-prod:'${commitId}'"
                }
            }
        }

        stage ('Create secrets for k8s') {
            when {
              branch 'master'
            }
            steps {
                container ('kubectl-istio') {
                    sh "kubectl delete secret '${PROJECTNAME}'-secrets --namespace='${NAMESPACE}' || true"
                    sh "kubectl create secret --namespace='${NAMESPACE}' generic '${PROJECTNAME}'-secrets \
                    --from-literal=SECRET='$PRODUCTION_SECRET' \
                    --from-literal=DATABASE_PASSWORD='$REFERRAL_DATABASE_PASSWORD'"
                }
            }
        }

        stage ('Deploy to k8s') {
            when {
              branch 'master'
            }
            steps {
                container ('kubectl-istio') {
                    sh "kubectl --namespace='${NAMESPACE}' apply -f ./k8s/configmap.yaml"
                    sh "sed -i 's/{{image_tag}}/${commitId}/g' ./k8s/deploy.yaml"
                    sh "sed -i 's/{{image_tag}}/${commitId}/g' ./k8s/cronjob.yaml"
                    sh "istioctl kube-inject -f ./k8s/deploy.yaml > ./k8s/deploy-istio.yaml"
                    sh "kubectl --namespace='${NAMESPACE}' apply -f ./k8s/deploy-istio.yaml"
                    sh "kubectl --namespace='${NAMESPACE}' apply -f ./k8s/cronjob.yaml"
                    sh "kubectl --namespace='${NAMESPACE}' rollout status deployment referral-nginx-phpfpm"
                    sh "kubectl --namespace='${NAMESPACE}' apply -f ./k8s/istio/istio-virtual-service-refferal-prod.yaml"
                    sh "kubectl --namespace='${NAMESPACE}' apply -f ./k8s/istio/service-entry-refferal-prod.yaml"
                }
            }
        }
    }
    post {
        failure {
            slackSend channel: "${SLACK_RECIPIENTS}", color: "danger", message: "${FAILURE_MESSAGE}"
        }
        success {
            slackSend channel: "${SLACK_RECIPIENTS}", color: "good", message: "${SUCCESS_MESSAGE}"
        }
    }
}
