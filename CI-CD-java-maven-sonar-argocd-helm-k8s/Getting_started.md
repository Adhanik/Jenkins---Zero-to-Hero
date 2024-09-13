
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

Next we have to install sonarqube - SonarQube Scanner on Jenkins from plugins

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

![Screenshot](CI-CD-java-maven-sonar-argocd-helm-k8s/sonarqube.png)

So now we know, Maven is already installed as part of docker container, we have intstalled sonar, but now how jenkins will authenticate with Sonar?

Since these are 2 diff applicaiton, we need to go to SonarQube, my account - securtiy , we will generate a token - copy token - Go to jenkins - Manage Jnekins - credentials - system - global cred - add creds - secret text

![Screenshot](CI-CD-java-maven-sonar-argocd-helm-k8s/cred.png)

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
```
Restart jenkins after this  

http://54.82.159.54:8080/restart

So now we have completed till this step.

![Screenshot](CI-CD-java-maven-sonar-argocd-helm-k8s/workflow.png)

# Summary

On jenkins, you have to install docker pipeline plugin and sonarqube scanner plugin
You add creds for sonarqube, docker and github
On you EC2, you have to install Jenkins, docker and sonarqube.

After this we need to run minikube on our cluster.

# KB and ArgoCD

The final step in our project is that we need a KB cluster and Argo CD

# Minikube

We will run a minikube cluster

# Operators and Controllers in KB

from 44:00

Whenever we want to install any KB controller ( for eg - ArgoCD HERE), the first thing that we should do is the installation of these tools should be taking place with KB operators.

Operators manage the lifecycle of KB controllers, so in future if there are any upgrades to the controllers, version, updates, for this purpose we should always use the operators, also operators make the installation proces very easy , and they come with some default config as well. 

# Installation of argoCD with operator

Go to operator Hub, and serach argo cd operator

So we will do installation of ArgoCD with the operator

Go to https://operatorhub.io/ and there you can see a bunch of operators. search Argo CD and click on Install . we will see a list of steps 

1. Install Operator Lifecycle Manager (OLM), a tool to help manage the Operators running on your cluster.

curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/install.sh | bash -s v0.28.0


2. Install the operator by running the following command:

kubectl create -f https://operatorhub.io/install/argocd-operator.yaml

amitdhanik@Amits-MacBook-Air ~ % kubectl get pods -n operators
No resources found in operators namespace.
amitdhanik@Amits-MacBook-Air ~ % kubectl get pods -n operators -w
NAME                                                 READY   STATUS    RESTARTS   AGE
argocd-operator-controller-manager-cbcd49899-td6lg   0/1     Pending   0          0s
argocd-operator-controller-manager-cbcd49899-td6lg   0/1     Pending   0          0s
argocd-operator-controller-manager-cbcd49899-td6lg   0/1     ContainerCreating   0          1s

We need to learn about Operators, how do they work and why we need operators in KB?


# Coming back to Jenkins

We have diff stages in Jenkins, and stages in Jenkins tells us what are the diff blocks that we are trying to build using this Jenkins pipeline

So we have mavent to build the application --> then run static code analysis --> build the image artifactory -> push the image artifactory to docker hub --> shell script which updates the manifest repo 

This is how our CI looks like.

For CD, we are using gitops model

# Jenkins Stages Explained

Refer jenkins file insdie spring-boot-app
Since we are using the Webhook, we need the checkout stage.

# First stage

Since we have configured docker as agent, jenkins tries to look for image as it will find no image

image 'abhishekf5/maven-abhishek-docker-agent:v1'

so it will download this image as it has to start creating this container and execute all the stages inside the container..

1. As we have provided the Github repo in our pipeline, jenkins will clone the whole repo. If we have not used SCM method, then we need to provide the checkout stage as Jenkins will not understand where our source code is.

# Build and test stage

2. Next stage for us is the 'Build and Test' stage

The docker image that we have defined earlier insdie our agent, we have maven already available in that image. So to build application we just need to run mvn clean package command

# How maven builds java application

mvn clean package inside this will find the pom.xml, which are written by pom.xml. pom.xml is responsible for getting the dependencies runtime, and building the application 

Whenever we are writing any application, we will be downloading a lot of dependencies. eg app needs a jar file, we will download the jar file and put it in a dependecy folder, 3rd party tools etc. 

You will push only the source code to github, nobody pushes the dependencies to github as they are quite large. Now when someone else uses our repo, it can by python or java app, in pythn we use requirements.txt file, and pip takes care of downloading all the dependencies.

# wht pom.xml does?

Similarly in java, developer writes a pom.xml file and he says that when he tried to run the application locally, he used all the dependencies mentioned in pom.xml. Now whenever someone else runs it, either in CI or personal lptop, you can use this pom.xml, and instead of downloading them locally, we can put everything in pom.xml, and there is a tool called MAVEN,  which when u run

   mvn clean pacakge OR mvn clean install,

This mvn clean package is used to build the target

# how jarvar files are created 

it downlaads each and evry pacakge from internet, and it will help java in building the application. for eg java archive, these are jarvar files. these are created using maven and pom.xml

So when we write cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app - in this path we have the pom.xml

This step would generate our artifact. You will see a folder `target` being created, inside which we could see the archive file that got created. We will copy the archive file to docker hub and execute it.This web archive file will run on port 8080

EG Of artifact - spring-boot-web.jar

### Static code anaylsis

3. Next we will do the static code anaylsis. For this, first we need to tell jenkins our SonarQube URL, because without url, jenkins will not be able to send the report, as it cannot send info to sonar server. 

mvn sonar:sonar - this is used to execute sonar. for this it needs one input, which is sonar authentication token ,and sonar url

withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_AUTH_TOKEN')]){
                    sh 'cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN 
                    -Dsonar.host.url=${SONAR_URL}'

## push image to docker hub

Since we will be pushing image to docker hub, we need to pass the credentials. ONCE we push it to dockerhub , only then our CD tool like argo CD will be able to deploy that iamge.

so firstly we need to pass docker creds to login to dockerhub and then Jenkins will trigger command to  build the Dockerfile, which will result in docker image and then finally push it to docker hub

# create the Dockerfile

We have created the Dockerfile

# Update Deployemnt file

This is the final stage, where we can use either Argo image updater or shell script. we will update the repo, you can create a new repo, or update the existing one.

We have created a repository - spring-boot-app-manifests, where we have deployment.yaml file , and we will update the image attribute in deployment.yaml. Once this is updated, we will push it back to github

Once deployment.yaml is updated, we will use argo CD to pull this deployment manifest automatically and deploy on KB cluster automatically


# Using helm

This can aslo be done using helm. we update the image tag using helm in values.yaml, and then push it to github

          run: |
            sed  -i 's/tag: .*/tag: "${{github.run_id}}"/' helm/go-web-app-chart/values.yaml

Once tag is updated in helm values.yaml, argo cd initiates a change, we dont have separate deployment.yaml in case of helm, as everything is handled by helm only



# Note - Docker credentials and Github credentials you need to put in Jenkins for it to succesfully execute the pipeline.

Add them in manage credentials
for github u can get from developers setting - gernerate your personal access tokens

Once all the stages are success, in last step we have the shell script which will update the deloyment.yaml

# We can check that our argo CD operator is already running

kubectl get pods -n operators   
NAME                                                 READY   STATUS    RESTARTS   AGE
argocd-operator-controller-manager-cbcd49899-td6lg   1/1     Running   0          5h32m
amitdhanik@Amits-MacBook-Air ~ %  

