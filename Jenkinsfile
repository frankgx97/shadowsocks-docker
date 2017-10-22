pipeline {
  agent any
  stages {
    stage('Preparation') {
      steps {
        git(url: 'https://github.com/nyanim/shadowsocks-docker.git', branch: 'master')
      }
    }
    stage('Build') {
      steps {
        sh 'sudo docker build --force-rm -t nyanim/shadowsocks:latest .'
      }
    }
    stage('Deploy') {
      steps{
        parallel(
          "Deploy" : {
            sh '''
            sudo docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD
            sudo docker push nyanim/shadowsocks:latest
            '''
            sh '''
            sshpass -p $SSH_PASSWORD ssh -o StrictHostKeyChecking=no -l $SSH_USER $SSH_HOST <<EOF 
            echo $SSH_PASSWORD | sudo -S docker-compose -f $SS_COMPOSE_FILE down
            sudo docker pull nyanim/shadowsocks
            sudo docker-compose -f $SS_COMPOSE_FILE up -d 
            uname -a
            '''
          },
          "Cleanup":{
            sh'''
            sudo docker images | grep '<none>' | awk '{print $3}' | xargs sudo docker rmi || true
            '''
          }
        )
      }
    }
    stage('Notification'){
      steps{
          emailext body: '''$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:

Check console output at $BUILD_URL to view the results.''', recipientProviders: [[$class: 'DevelopersRecipientProvider']], replyTo: '$MAIL', subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!', to: '$MAIL'

      }
    }
  }
}