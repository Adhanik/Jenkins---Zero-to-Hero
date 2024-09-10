
# Intro

We will be building a Java application with Maven, setup sonar server locally for image scanning, build docker iamge and push to github. We will update the manifest repo with shell script , and then using ArgoCD we will deploy this manifest automatically on the KB cluster.

We have a simple spring boot application in java which we will be making use of.



We have 2 Git repositories, the first one which makes it a CI, where Jenkins is involved, and the second part, CD, where we have Argo CD

Jenkins pipeline in no way is triggering our CD process.



# CI vs CD

CI - Ensure all build is passed with correct test cases etc.

CD - Ensures our deployment is done. We are making use of KB as deployment platform.

# Jenkins as Orchestrator

Developer stores the code in Git repo, and Jenkins is the orchestrator which is responsible for watching the commits/PR on this repository. Whenever a PR is created, Jenkins has to be triggered.

# How Jenkins is triggered from Github (IQ1)

Webhook - Whenever we use Webhook, instead of jenkins watching your repo, Git sends notification to Jenkins.

# CI - The continuous Integration Lifecycle

1. Go to Jenkins. Get the jenkins url
2. Generate the secret, and use this in <repo>/settings/hooks/new
3. Put the jenkins url in your Github settings.
4. Define the action for which webhook has to be triggered.
5. Now whenever developer creates a PR, GIT will send notification to Jenkins, and jenkins will trigger the pipeline.

6. Write a Jenkinsfile, using which you will try to perform a set of actions on Jenkins. We will use Maven(as application is build on Java)

# IQ 2 - What type of jenkins files are you using?

We use Declarative jenkins file instead of scripted pipelines as DP are much easy to collabrate and share.

# IQ 3- What type of agent are you using in your Jenkins?

We are using Docker agents, as we dont have to install maven, python etc and they are lightweight in nature.

7. Using MAVEN, we will build the application . Install the maven plugin OR
8. For each of the stages, we can use a Docker agent. When we use a Docker Agent, we dont have to worry about the installations as docker images are available for all

9. As part of BUILD, 

    a. unit test will run. Once unit test are run, 
    b. we can perform static code analysis
    c. Once this is success we move to next stage
    d. If our BUILD fails, we can configure email plugin/notification 

10. As part of next stage, we will use Sonarcube

a. We will match the code pass is matching with compliance of our org
b. does it have error less than x% 
c. Are there any security vulnabrlities inside the code that is written in PR? if yes, we can send mail notification. If no, we can proceed with creation of DOCKER IMAGE

11. For next stage, again we can use a docker agent, or install the docker plugin, and run command like docker build, whjich gives us the docker image

12. We will send this Docker image to container registry. (docker hub, ECR)


At the end of CI, we have a image ready, and this image has a new tag. If our previous image was on v1, our new artifact will be like web-app:v2

Once the image is pushed, how does our CD gets triggered?

# CD - Continous Delievery Process

Previously, we would configure Ansible Playbook, or shell script to initiate the CD process, and involve them in CI pipeline only.

a. Once image is build, we trigger the Ansible playbook or shell script, which will deploy the artifacts to KB platform. 

The problem with this was that its not scalable, and tools like ansible are not designed for CD. Hence we used CD tool were Gitops based. GitOps follow a similar strategy where we have a git repo, and this repo will have our application manifest. Application manifest are KB pod.yaml , deployment.yaml, svc.yaml

# Why do we need to put these thing in GIT repo? and why cant we put them simply in our CI pipeline?

Because we dont have a proper mechanism. suppose we have to add a volume or mount point to our pods. Now the CI pipeline is triggered whenever there is change in source code, so adding a new volume to pod is not easy this way. as then he has to login to KB cluster, and update pod.yaml

There is no verification in this case, no source of truth. Hence we make use of git repo, not just for source code, but also for application manifest.

# How does ArgoCD or GITOPS tool comes to know that there is a new image in CI, so my helm chart should be updated with new one that was created in CI PIPELINE?

1. We can make use of ArgoImage Updater. It continuously monitors the docker hub or any container registry, and whenever a new image is pushed to the container registry, Argo Image Updator will update the GIT repo(this is application manifest GIT repo) with new version in helm chart. 

The argo image updater will create a new commit. As soon as this commit is created, GITOPS tool, which are KB controller, sitting inside KB cluster, argo cd will maintian the state btw your Github and KB cluster. 

2. We have ArgoCD, which is continuously watching the GIT repo, and whenever it sees a change in the Git repo, take the new deployment.yaml or helm chart, and deploy it to KB cluster.

Also if someone tries to change the KB cluster, argo CD will deny, as the source of truth for KB is git. ArgoCD will override the manaul change.

We can write another Jenkins pipeline as well or use Github actions, push the new image to GIT, and then deploy it to KB cluster.


# Summary

We have a Git repo, which holds the source code, which is a java application. --> as soon as developer creates PR in this repo, we have configured webhooks, using webhook, we trigger the jenkins pipeline - we have created a declarative jenkins piplenine - as part of this pipeline we have multiple stages like build - > maven is used, and if build is success (which is verified by running some unittest), then in next stage, we perfomr some static code analysis, after this in last stagw we have SAST/DAST TOOLS, wehere we verifgy the application security , if this new change introduces any security vulnebrality -> if any of these things fail, we would send email notificatioin  -- after all this stages are successful - we will create a docker iamge from the docker file using shell command which we have stored in git repo, and as soon as docker iamge is created, again using shell command we push this image to continaer registry - dockerhub 

    Developer
        |
   Creates PR in
  Git Repo (Java App)
        |
        V
  Webhook Trigger
        |
        V
   Jenkins Pipeline
 (Declarative Pipeline)
        |
        V
-------------------------
|        Build (Maven)    | --- [if Success] --->
-------------------------
        |
        V
-------------------------
|    Unit Tests Passed    | --- [if Success] --->
-------------------------
        |
        V
-------------------------
| Static Code Analysis    | --- [if Success] --->
-------------------------
        |
        V
-------------------------
|  SAST/DAST Security     | --- [if Success] --->
|    Vulnerability Check  |
-------------------------
        |
   [if Any Stage Fails] -----> Send Email Notification
        |
        V
-------------------------
|  Docker Image Build     |
| (from Dockerfile in Git)|
-------------------------
        |
        V
-------------------------
|  Push Docker Image to   |
|   DockerHub (Registry)  |
-------------------------


Coming to CD process, once the image is pushed to Docker hub or ECR, We have a KB cluster, insside which we have deployed 2 continous delivery tools, one is the ArgoImage Updater, and the other tool that we have is Argo CD -> Argo image updater continuously monitors the image registry, and as soon as new image is created, it picks up the new image , andupdate the new image in another git repository amd this git repository is only for manifest - helm charts or customsie or pod, deployment.yaml. --> as soon as this repo is updated with new image, argo cd takes new image and deployes on KB cluster

    Docker Image 
  Pushed to DockerHub
          |
          V
---------------------------------
|  Argo Image Updater            |
| (Monitors Image Registry)      |
---------------------------------
          |
   [New Image Detected] --------->
          |
          V
---------------------------------
| Updates Git Repo (Manifests)   |
| (Helm Charts, Kustomize, etc.) |
| deployment.yaml                |
---------------------------------
          |
   [Git Repo Updated] ----------->
          |
          V
---------------------------------
|        Argo CD                 |
| (Pulls new image from Git)     |
---------------------------------
          |
          V
----------------------------
| Deploys on KB Cluster     |
----------------------------
