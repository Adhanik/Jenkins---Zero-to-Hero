
# Creating EC2 Instance using TF

Firstly, we have to create a EC2 instance (ubuntu) and install jenkins on it. We could have manually created the EC2, but we decided to go ahead with TF, and wrote the TF file.

# Installing Jenkins on EC2 using TF

We decided to install jenkins using TF only, using user_data, which we have tried till now, but jekins is not getting installed via this method.

# Other ways of Installing Jenkins using TF

1. For us, the user_data did not work, so we will discard it from our main.tf . We have few other methods also via which we can install Jenkins, one of them being the Terraform provisioners. You can read in details about TF provisioners in TF Related earnings.

We decided not to go forward with TF provisioners as well, as debugging them is hard because TF apply marks it as pass and does not give much information if our scropt failed

### 2. **Use an AMI with Jenkins Pre-installed:**

This method is being used in most of the orgs, and we will use this . We will Create a custom AMI that already has Jenkins installed and configured. You can do this by:

1. We will launch a EC2 manually from AWS Console, install Jenkins on it, create a AMI, and then reference that AMI in our main.tf

2. We will make change to variable.tf and use this AMI instead of which we are using now.
3. Once you have launced a EC2 from console, use below commands to install Jenkins on ubunt machine

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

**Note: ** By default, Jenkins will not be accessible to the external world due to the inbound traffic restriction by AWS. Open port 8080 in the inbound traffic rules.

# Check Jenkins running or not on manually created EC2

systemctl status jenkins
● jenkins.service - Jenkins Continuous Integration Server
     Loaded: loaded (/usr/lib/systemd/system/jenkins.service; enabled; preset: enabled)
     Active: active (running) since Tue 2024-09-03 09:20:04 UTC; 1min 15s ago


# Create AMI of this EC2

Go to actions - Image and templates - Create Image - give name, and create the AMI

# Delete the manually created EC2

Once the AMI is created, you can safely terminate the original EC2 instance if it’s no longer needed.

# Using the AMI Later:

You can now launch new EC2 instances using the AMI you created. This will replicate the state of the original instance, including all installed software and configurations.

We will pass this ami in our variable field. After doing tf apply, we ssh to our new EC2 created using TF

# EC2 created using TF

```
ssh ubuntu@54.85.182.252 -i mykeypair.pem

ubuntu@ip-172-31-88-218:~$ systemctl status jenkins
● jenkins.service - Jenkins Continuous Integration Server
     Loaded: loaded (/usr/lib/systemd/system/jenkins.service; enabled; preset: enabled)
     Active: active (running) since Tue 2024-09-03 09:33:54 UTC; 6min ago
   Main PID: 561 (java)
      Tasks: 38 (limit: 1130)
     Memory: 349.0M (peak: 349.8M)
        CPU: 22.694s
     CGroup: /system.slice/jenkins.service
             └─561 /usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --webroot=/var/cache/jenkins/war --htt>

Sep 03 09:33:48 ip-172-31-88-218 jenkins[561]: Jenkins initial setup is required. An admin user has been created and a password g>
Sep 03 09:33:48 ip-172-31-88-218 jenkins[561]: Please use the following password to proceed to installation:

ubuntu@ip-172-31-88-218:~$ 

```
Our jenkins is up and running now using TF.

# Add S.G and complete Jenkins installation

We have not created S.G tf file, so go to default SG attached to our EC2 Instance, and on that EC2, allow custom tcp traffic on port 8080 from you laptop publicIP.

After this, if you do http://<publicip of your EC2>:8080 ---> you should get the Jenkins set up page.

After selecting the installed plugins, Jenins will be setup for you, and you will get a url where you can access it - http://54.85.182.252:8080/


# Jenkins Architecture

Jenkins Architecture was discussed, which you can get in Hero to Zero section. After u have gone through it, we will install docker on our EC2

# Configure Docker

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

Now swithc user to jenkins (jenkins user is created by default when jenkins is created)

```su - jenkins```

#  Check jenkins user has access to docker

We will run ```docker run hello-world``` command to check. It should generate a msg showing docker steps

```
jenkins@ip-172-31-88-218:~$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c1ec31eb5944: Pull complete 
Digest: sha256:53cc4d415d839c98be39331c948609b659ed725170ad2ca8eb36951288f81b75
Status: Downloaded newer image for hello-world:latest

```

So, now jenkins user is alos able to create/run the containers. Restart jenkins just to make sure it picks up the configuration changes which we have done.

# Install the Docker Pipeline plugin in Jenkins:

To run docker as agent, Jenkins needs to have configuration  comamnds run on docker container

from plugins download docker-pipeline plugin.


# Freestyle vs Pipeline

Freestyle project in a Jenkins pipeline follows Declarative approach. It means it cannot be shared with team members.

For eg u are writing a calculator application in python, and u want to modify addition functionality. we will raise a PR in github, and some of our peer will review it. 

In writing a freestyle project,the major drawback is that  it cannot go through all of this workflow, which is the workflow followed by most of the tools. So to overcome this process , and other drwabacks as well (this was one of the drawbacks), jenkins came up with a pipeline approach. 

In pipelline approach you can write a declarative or scripted pipeline.  You can write your pipeline as code here. This groovy code you can easily put in your git repo, and it can be reviewed by peers, and you can easily see the code for all jobs (suppose there are 100 jobs), so its easy to see them on github, and track the previous version easily. Hence we should always go with pipeline approach

You can read more in Freestyle vs Pipeline

# Creating a Pipeline


A simple jenkins pipeline to verify if the docker slave configuration is working as expected. We have already installed the docker-pipeline plugin, so Jenkins would request Docker to lend a container to run the pipeline whenever we trigger the build. 

Lets try this out with a simple script. We will select - Pipeline script for SCM, which means that we will be picking a pipeline from source code management repository like github, instead of writing it for ourself.

We have created my-first-pipeline folder inside which we have placed our groovy script. We will give this in script path and run it.

# Build the pipeline

So as you know, rn we have only one EC2 instnace and no worker nodes. So where does our build gets executed? As we know, Jenkins master or EC2 is mostly used for scheduling purpose only.


Firstly, Jenkins fetches the code from Github, and we see that jenkins pull image 'node:16-alpine', executes node --version, and exists from that container once the build is successful

```
+ node --version
v16.20.2

docker stop --time=1 e00a0
$ docker rm -f --volumes e00a
```
You can see docker container is deleted

We can see from below, there are no running containers as well
```

ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ubuntu@ip-172-31-88-218:~$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED        STATUS                    PORTS     NAMES
7dfc7b463f33   hello-world   "/hello"   13 hours ago   Exited (0) 13 hours ago             zen_napier
ubuntu@ip-172-31-88-218:~$ 

```

# Summary

Jenkins requested docker to create one container using docker pipeline plugin that we had configured, it asked to give one container so that it can execute my pipeline which is a nodejs application. After execution, jenkins terminated the c1 container

During execution, requests one container

```
      Jenkins Master
            |
            V
  --------------------------
  |          |            |
  V          V            V  
Container  
(Docker)   
```
After execution, deletes the container. only when there is a request, a container is created. While managing of worker nodes is not that easy, for eg, upgrade. hence docker is used as agent.

```
      Jenkins Master
            |
            V
  --------------------------
  |          |            |
  V          V            V  

```


# Multi Stage Multi Agent 

Suppose you have a 3 tier application, frnotend, backend and Database. Database related CI/CD has to be executed on a VM which has CentOS, frontend & backend has to be executed on machine that has Ubuntu or java instlled or oracle installed. How do we solve this problem?

For managing a multi tier application, we will create multiple stages, and initially we will not select any agent, inside the stages, for eg if its a backend stage, and our application is a java, we will declare agent here as maven, similarly for frontend, we will use agent as node or react, and if its DB related thing, we will use any image like mysql

# Creating Multi Stage Multi Agent 

We have created our pipeline where we have created 3 stages, each with their own agent, so it should create 3 containers.Inside mysql, we will run some queries, and never use latest image, always use tag.


We can see containers are created dynamically, inside backend container maven targets are runing, and inside frontend node js related targets are running.

In real life scenario, we will not be running steps like sh 'mvn --version'. We will be running mvn install package , for frontend npm run, npm install all these things

If we do docker ps, we can containers, initially no container, then we see containers, and as soon as steps got executed, it terminates them

```
ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```
ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS     NAMES
24e0dd1e5169   node:16-alpine   "docker-entrypoint.s…"   9 seconds ago   Up 8 seconds             keen_kalam
ubuntu@ip-172-31-88-218:~$ 
```

```

ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS         PORTS                 NAMES
f9ac9a717d11   mysql:latest   "docker-entrypoint.s…"   10 seconds ago   Up 7 seconds   3306/tcp, 33060/tcp   objective_lichterman
ubuntu@ip-172-31-88-218:~$ 


```

```
ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ubuntu@ip-172-31-88-218:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

```

So if our organisation is using VM based approach we should  always look at migrating them to docker based container approach, as it saves the cost , and saves a lot of time also. if here we would be using VM, then we would be managing 3 VM. And suppose wheever nodejs or maven  version is increased, we need to increase it in VM. this all can be avoided using this docker container based approach.