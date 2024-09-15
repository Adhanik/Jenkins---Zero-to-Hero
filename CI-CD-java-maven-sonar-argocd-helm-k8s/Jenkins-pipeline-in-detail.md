
# First 

pipeline {
  agent {
    docker {
      image 'abhishekf5/maven-abhishek-docker-agent:v1'
      args '--user root -v /var/run/docker.sock:/var/run/docker.sock' // mount Docker socket to access the host's Docker daemon
    }
  }

}
This part of your Jenkins pipeline defines the **agent** configuration, which controls where and how the pipeline's stages will execute. Here’s a breakdown of what it does step by step:

1. **`pipeline { ... agent { docker { ... } } }`**:
   - This specifies that the pipeline will run inside a **Docker container**. Instead of executing directly on the Jenkins agent (machine), it will run inside a specified Docker image.

2. **`image 'abhishekf5/maven-abhishek-docker-agent:v1'`**:
   - This tells Jenkins which Docker image to use for the pipeline execution. In this case, it will pull and run the Docker image named `abhishekf5/maven-abhishek-docker-agent:v1`. This Docker image is expected to contain tools such as Maven, Java, and other dependencies needed for building your Java project.
   - The format for Docker images is `username/repository-name:tag`. Here, `abhishekf5` is the Docker Hub username, `maven-abhishek-docker-agent` is the repository (image name), and `v1` is the tag (version).

3. **`args '--user root -v /var/run/docker.sock:/var/run/docker.sock'`**:
   - The `args` parameter allows you to pass additional Docker options to customize how the container runs. In this case:
   
     - `--user root`: This specifies that the container should run as the `root` user. In Docker containers, running as a non-root user is more secure by default. However, certain operations (e.g., installing software or managing files) may require root permissions, which is why it's specified here.
     - `-v /var/run/docker.sock:/var/run/docker.sock`: This mounts the Docker socket (`/var/run/docker.sock`) from the **host** (the machine running the Docker daemon) into the **container**. This gives the container access to the host machine’s Docker daemon. This is crucial because it allows the container to run Docker commands as if it were running directly on the host.
   
     By mounting the Docker socket, the container can build, run, and manage Docker containers from within itself.

### Key Concepts:
- **Agent**: Specifies where the pipeline should execute. Here, the agent is a Docker container.
- **Docker Image**: Specifies a pre-built Docker image that contains the required environment and tools for the pipeline execution.
- **Docker Socket Mounting**: Mounting the Docker socket allows the container to communicate with the host machine’s Docker daemon, enabling it to run Docker commands within the pipeline (e.g., building and pushing Docker images).

### Why Use This Configuration?
- **Isolation**: Running the pipeline inside a container isolates the build environment, ensuring that dependencies and configurations specific to the build process don’t affect the host machine.
- **Consistency**: By using a specific Docker image (`abhishekf5/maven-abhishek-docker-agent:v1`), you ensure that every time the pipeline runs, it runs in a consistent environment with all the necessary tools.
- **Docker in Docker**: Mounting the Docker socket enables "Docker in Docker" functionality, which allows the pipeline to run Docker commands (such as building and pushing images) from within the container itself.

In summary, this configuration sets up the pipeline to run inside a pre-configured Docker container with root access and the ability to run Docker commands using the host’s Docker daemon.

# Build and Test

    stage('Build and Test') {
      steps {
        sh 'ls -ltr'
        // build the project and create a JAR file
        sh 'cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'
      }
    }


### What Does This Stage Do?

1. **`sh 'ls -ltr'`**:
   - This command lists the contents of the current directory, displaying the files and directories in a detailed, reverse time order (`-ltr`). It’s useful for debugging or checking the directory structure before running build commands.

2. **`sh 'cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'`**:
   - This changes the directory to `CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app`.
   - **`mvn clean package`** is a **Maven command** used to clean and build the project.

### Breakdown of `mvn clean package`:
   - **`mvn clean`**:
     - This phase removes any previously compiled files or JARs (Java ARchive files) from the `target` directory. Essentially, it ensures that the build starts from a clean state without any leftover artifacts.
   
   - **`mvn package`**:
     - This phase compiles the source code, runs the tests, and creates a JAR or WAR file (depending on the project configuration) in the `target` directory. The JAR/WAR file contains the entire application with its dependencies, ready for deployment.

### Is the Application Ready After This Stage?
- After this stage completes, the project will have produced a **JAR** (for a typical Spring Boot project) or **WAR** file inside the `target` directory. However, the application is not yet running. 
   - The **end result** of this stage is the **packaged application**. You have a build artifact (a JAR or WAR), but to actually **run** the application, you still need to deploy or execute the JAR file, typically by running `java -jar <name-of-the-jar>.jar`.

### If This Were a Python Application, What Would You Use Instead of Maven?

For Python applications, you would typically use:

1. **`virtualenv` or `venv`** for creating isolated environments to install dependencies.
2. **`pip`** or **`pipenv`**:
   - **`pip`**: The package installer for Python, used to install dependencies from a `requirements.txt` file.
   - **`pipenv`**: Combines dependency management and virtual environments, commonly used in modern Python projects.
   
3. **`setuptools` or `pyproject.toml`**:
   - For building Python projects, you would define dependencies and other project details in `setup.py` or `pyproject.toml`.
   - To package the Python application, you might use commands like:
     - **`python setup.py sdist bdist_wheel`** to build a source distribution and wheel package.
   
4. **`tox`**:
   - For running tests across different environments and ensuring compatibility, similar to running unit tests in Maven.

In summary, for Python, you would:
   - Install dependencies via `pip install -r requirements.txt`.
   - Use `setup.py` or `pyproject.toml` to package the application.
   - Use `tox` or `pytest` to run tests.

The equivalent Python stage might look like:
```groovy
    stage('Build and Test') {
      steps {
        sh 'ls -ltr'
        // Install dependencies and run tests
        sh 'pip install -r requirements.txt && pytest'
      }
    }
```

The **end result** of this stage in Python would be a packaged Python application or a wheel file.

# What we do with artifact produced after build and test stage?

Yes, you're absolutely right! The artifact (JAR file) produced by the **`mvn clean package`** step is used in the subsequent **"Build and Push Docker Image"** stage to build a Docker image and push it to Docker Hub.

Here’s how it works step-by-step:

### 1. **Build the Docker Image**:
- **Artifact Creation**: 
   - In the earlier stage, **`mvn clean package`** generates a JAR file (`spring-boot-web.jar`) in the `target` directory.

In our script, we go to this path, wehere docker file is kept, and then build it with name adminnik/ultimate-cicd:${BUILD_NUMBER}


- **Dockerfile**:
   - The **Dockerfile** specifies a **base image** (`adoptopenjdk/openjdk11:alpine-jre`), which provides a lightweight Java runtime environment.
   - The **artifact path** is passed as an argument to the Docker build process (`target/spring-boot-web.jar`).
   - Inside the Dockerfile, this artifact is copied into the Docker image (`COPY ${artifact} app.jar`).
   - The **entry point** (`ENTRYPOINT ["java","-jar","app.jar"]`) ensures that when the container is started, it will run the JAR file (`app.jar`), which is your Spring Boot application.

### 2. **Push Docker Image to Docker Hub**:
   - The Docker image is built with a specific tag (`${DOCKER_IMAGE}`), which uses your Docker Hub repository (`adminnik/ultimate-cicd:${BUILD_NUMBER}`).
   - The script then uses **`docker.withRegistry`** to authenticate and push the image to Docker Hub using the credentials (`docker-cred`).

### Overview of What's Happening:
- **JAR to Docker Image**: 
   - You package your Spring Boot application into a JAR file (`mvn clean package`).
   - The JAR file is then included in a Docker image, built from the **Dockerfile**.
   
- **Push to Docker Hub**: 
   - The Docker image is pushed to Docker Hub with a tag that includes the current build number (`adminnik/ultimate-cicd:${BUILD_NUMBER}`).

In short:
1. **`mvn clean package`** creates the JAR file.
2. The JAR file is used to build a Docker image.
3. The Docker image is pushed to Docker Hub for deployment or further use.

This setup allows you to package the application into a container for easy deployment in environments like Kubernetes.

# SONARQUBE

SonarQube performs **static code analysis**, which means it checks your code for potential issues such as bugs, code smells, vulnerabilities, and code quality without actually running the application. This process is important for maintaining a clean and secure codebase.

Here's what happens in your SonarQube stage:

### 1. **SonarQube Setup**:
   - **`SONAR_URL`**: Specifies the URL where your SonarQube server is hosted (`http://3.94.214.89:9000/`).
   - **`SONAR_AUTH_TOKEN`**: Uses the `withCredentials` block to securely retrieve your SonarQube authentication token (`sonarqube`) to authenticate with the server.

### 2. **SonarQube Execution**:
   - The command `mvn sonar:sonar` runs the SonarQube Maven plugin, which triggers the static code analysis.
   - **Options**:
     - **`-Dsonar.login=$SONAR_AUTH_TOKEN`**: Authenticates the request using your SonarQube token.
     - **`-Dsonar.host.url=${SONAR_URL}`**: Specifies the SonarQube server's URL to which the analysis data is sent.

### 3. **What SonarQube Does**:
   - **Analyzes the Source Code**: 
     - **SonarQube** scans the source code, not the artifact (JAR). It looks at the code files in your project (e.g., Java files in `src/main/java`).
     - **Static Code Analysis**: It checks for code smells, bugs, vulnerabilities, and even tracks code duplications. It identifies issues that could affect performance, security, maintainability, etc.

### 4. **Uses of SonarQube**:
   - **Code Quality**: Ensures high code quality by identifying code smells, anti-patterns, and technical debt.
   - **Security**: Helps discover vulnerabilities in the code (like SQL injections, XSS).
   - **Maintainability**: Improves the maintainability of code by offering metrics like cyclomatic complexity and identifying duplicated code.
   - **Compliance**: It can enforce coding standards and guide developers to follow best practices.
   
### Important: 
- **Artifact Scanning**: SonarQube analyzes the source code, **not the built JAR file**. It scans the project files (`.java`, `.xml`, etc.) during the build process. Hence, it’s part of the build but doesn’t interact with the artifact (JAR).



### Build and push Docker image

    stage('Build and Push Docker Image') {
      environment {
        DOCKER_IMAGE = "adminnik/ultimate-cicd:${BUILD_NUMBER}"
        // DOCKERFILE_LOCATION = "CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app/Dockerfile"
        REGISTRY_CREDENTIALS = credentials('docker-cred')
      }
      steps {
        script {
            sh 'cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app && docker build -t ${DOCKER_IMAGE} .'
            def dockerImage = docker.image("${DOCKER_IMAGE}")
            docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
                dockerImage.push()
            }
        }
      }
    }


Sure! This Jenkins pipeline step is related to building and pushing a Docker image. Here's a step-by-step explanation of what each part does:

1. **`steps { script { ... } }`**:
   - This block defines a series of steps to be executed in a scripted pipeline. The `script` block allows you to write Groovy code, giving you more control over the pipeline execution.

2. **`sh 'cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app && docker build -t ${DOCKER_IMAGE} .'`**:
   - `sh` is a Jenkins step that runs a shell command.
   - `cd CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app` changes the directory to where the Dockerfile is located. This is necessary because Docker commands are typically run in the context of the directory containing the Dockerfile.
   - `docker build -t ${DOCKER_IMAGE} .` builds a Docker image from the Dockerfile in the current directory (`.`). The `-t ${DOCKER_IMAGE}` flag tags the image with the name specified by the `${DOCKER_IMAGE}` environment variable. The `${DOCKER_IMAGE}` variable should be defined elsewhere in your pipeline or environment and includes the name and optionally the version (e.g., `my-app:latest`).

3. **`def dockerImage = docker.image("${DOCKER_IMAGE}")`**:
   - This line defines a Groovy variable `dockerImage` that holds a reference to the Docker image created in the previous step. `docker.image("${DOCKER_IMAGE}")` retrieves this image using the name specified by the `${DOCKER_IMAGE}` variable.

4. **`docker.withRegistry('https://index.docker.io/v1/', "docker-cred") { dockerImage.push() }`**:
   - `docker.withRegistry('https://index.docker.io/v1/', "docker-cred")` specifies that the Docker commands inside the block should use the Docker registry at `https://index.docker.io/v1/` (which is Docker Hub). The `"docker-cred"` argument refers to the Jenkins credential ID that contains authentication details for Docker Hub. This ID should be configured in Jenkins' credentials management.
   - `dockerImage.push()` pushes the Docker image to the specified Docker registry (Docker Hub) using the tag specified earlier. This makes the image available in the registry for others to pull or use.

**Summary**:
- This pipeline step builds a Docker image from a Dockerfile located in the `CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app` directory, tags it with the name stored in the `${DOCKER_IMAGE}` variable, and then pushes this image to Docker Hub using credentials stored in Jenkins.

Make sure to have the `${DOCKER_IMAGE}` variable set and the Docker credentials properly configured in Jenkins for this step to work correctly.


# Update delployment file

  stage('Update Deployment File') {
        environment {
            GIT_REPO_NAME = "Jenkins---Zero-to-Hero"
            GIT_USER_NAME = "Adhanik"
        }
        steps {
            withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                sh '''
                    git config user.email "amitdhanik3@gmail.com"
                    git config user.name "Adhanik"
                    BUILD_NUMBER=${BUILD_NUMBER}
                    sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml
                    git add CI-CD-java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml
                    git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                '''
            }
        }
    }

