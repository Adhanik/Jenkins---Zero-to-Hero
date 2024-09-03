
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

Jenkins Architecture was discussed, which you can get in Hero to Zero section.

