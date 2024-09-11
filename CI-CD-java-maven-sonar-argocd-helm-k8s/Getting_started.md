
We will be launcing a t2.large instance for our Project . 

Note - Before proceeding further, have the java application on your local.


# Launch EC2

We have launced a t2.large ubuntu machine, and we will isntall Jenkins on top of it.

### Run the below commands to install Java and Jenkins

Install Java
```
    sudo apt update
    sudo apt install openjdk-17-jre

```

Verify Java is Installed
```
    java -version
```

Now, you can proceed with installing Jenkins

```
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins

```
Jenkins will not be accessible as of now, since S.G are not configured properly.
Add inbound rule, like all traffic for now, as we will be exposing this diff applications like sonarcube jenkins

# Accessing Jenkins

Since we have installed Jenkins on our EC2, we will use public ip of ec2 on port 8080 to access the Jenkins application.

29736ab180334c539e7a47eb390ffbf2

# Writing a Pipeline

Freestyle project is a legacy way of creating jenkins pipeline. The good way is using jenkins pipeline way, we will be writing it in groovy scripting, it can be stored in git repo, and collabrated with other, which is not available with freestyle.

Jenkins gives us 2 ways -

1. Write your own groovy script
2. Pipeline script from source code manager

We will be creating our Jenkins file inside the spring-boot-app folder. WE HAVE CLONED THE sping-boot-app for now .


# Configuring jenkins job

We will be selecting - Pipeline script from SCM, SCM select as GIT, Repo url - Github repo where your code is hosted. This repo will be cloned by github

For public repo, we dont need any credentials.

In script path, give the path where the jenkins file is actually kept. After Jenkins has cloned the git repo, it will start seraching for the jenkins file. The naming convention can be anyting for jenkinsfile, and it can be present in any folder.

So we have written a jenkinsfile that is imported from SCM, the purpose of it to execute all other task of continuous Integration only.

# Configuring agent

One of the good ways of writing a Jenkins pipeline is to use docker as agent. USE DOCKER CONTAINER AS AGENTS FOR YOUR DOCKER PIPELINE

Since Docker containers are more resource-efficient compared to traditional VMs like EC2 instances, and they need lesser configurations. Also VM will be running all the time. Also all the configuration like maven, sonarkube needs to be installed on all the worker node. Hence we use docker container, config gets created with container, and then after work gets deleted.

# Downloading plugins - docker maven sonarqube
To run docker as agent, Jenkins needs to have configuration comamnds run on docker container.

From plugins download docker-pipeline plugin.
Maven is downloaded along with this plugin

Next we have to install sonarqube - SonarQube Scanner

# Install sonar server on my EC2

Configure a Sonar Server locally
```
sudo su - 
apt install unzip
adduser sonarqube

Switch to that user -->

  sudo su - sonarqube
  sonarqube@ip-172-31-18-109:~$ 

Download sonar binary

wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip
unzip *
chmod -R 755 /home/sonarqube/sonarqube-9.4.0.54424
chown -R sonarqube:sonarqube /home/sonarqube/sonarqube-9.4.0.54424
cd sonarqube-9.4.0.54424/bin/linux-x86-64/
./sonar.sh start
```

sonarqube@ip-172-31-18-109:~/sonarqube-9.4.0.54424/bin/linux-x86-64$ ./sonar.sh start
Starting SonarQube...
Started SonarQube.
sonarqube@ip-172-31-18-109:~/sonarqube-9.4.0.54424/bin/linux-x86-64$ 

by default sonar server will start on port 9000

You can access it by <public-ip of EC2>:9000

admin admin is Username/Password

![Screenshot](/Users/amitdhanik/Jenkins/CI-CD-java-maven-sonar-argocd-helm-k8s/Screenshot 2024-09-11 at 2.13.15 PM.png)


So now we know, Maven is already installed as part of docker container, we have intstalled sonar, but now how jenkins will authenticate with Sonar?

Since these are 2 diff applicaiton, we need to go to SonarQube, my account - securtiy , we will generate a token - copy token - Go to jenkins - Manage Jnekins - credentials - system - global cred - add creds - secret text

![Screenshot](/Users/amitdhanik/Jenkins/CI-CD-java-maven-sonar-argocd-helm-k8s/Screenshot 2024-09-11 at 2.13.58 PM.png)

So, our Docker, Maven and Sonarkube configuration is done now. For tests, we will consider Unit test only, no extra configuration is needed for them.

# Docker

We need to install docker locally on our laptop. We will install it on our EC2 instance 
We will be installing Docker on EC2 machine
```
sudo apt install docker.io
```

We will grant access of Docker daemon to Jenkins user as well as ubuntu user as it is not granted by default, only root user has access to Docker daemon.

We will swithc to root user, docker installation creates a group called user, whoever wants access to this docker daemon, or whoever wants to create container/access docker should be part of docker group.
then restart docker daemon.

```
sudo su - 
usermod -aG docker jenkins
usermod -aG docker ubuntu
systemctl restart docker

Restart jenkins after this  

http://54.82.159.54:8080/restart

So now we have completed till this step.

![Screenshot](/Users/amitdhanik/Jenkins/CI-CD-java-maven-sonar-argocd-helm-k8s/Screenshot 2024-09-11 at 2.11.25 PM.png)