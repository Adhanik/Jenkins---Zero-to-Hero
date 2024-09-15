Your understanding of how the `agent` directive works in a Jenkins pipeline is mostly correct. Let me break it down and clarify the details for you:

### What Happens When You Declare an `agent` Inside a Jenkins Pipeline

1. **Docker Container Request**:
   - When you define the `agent` with `docker`, Jenkins requests a Docker container to be used for executing the pipeline stages.
   - In your example, Jenkins will pull the Docker image `abhishekf5/maven-abhishek-docker-agent:v1` from Docker Hub (if it isn't already present on the Jenkins server).

2. **Spin-Up the Container**:
   - Jenkins spins up a Docker container using the specified image.
   - The container is created with the options provided, such as mounting the Docker socket (`-v /var/run/docker.sock:/var/run/docker.sock`) to allow Docker commands to be run from within the container itself.

3. **Run Pipeline Steps Inside the Container**:
   - Once the container is up, all the steps within your pipeline (such as the `Checkout` stage) will execute **inside** this container.
   - For example, the `sh 'echo passed'` command will be executed within the Docker container.

4. **Container Cleanup**:
   - After all the steps in the pipeline are executed, the Docker container is **automatically removed** by Jenkins. This ensures that no unnecessary resources are consumed by idle containers.

### Why Use the `agent` Inside a Jenkins Pipeline?

- **Consistency**: By using a Docker container, you're ensuring that the environment for running your pipeline is consistent. It isolates the pipeline execution environment, avoiding conflicts with tools or dependencies installed on the Jenkins server.
  
- **Custom Build Environment**: The `agent` allows you to use custom Docker images, like `abhishekf5/maven-abhishek-docker-agent:v1`, which may contain pre-installed dependencies or specific versions of tools like Maven. This way, the environment is tailored to the pipeline's needs.

- **Resource Efficiency**: Since the container is spun up for the duration of the pipeline execution and then removed, you don't need to maintain dedicated virtual machines or Jenkins agents for each type of build environment. It also avoids polluting the main Jenkins server with various tools and dependencies.

- **Isolation**: Each build runs in its own isolated Docker container, meaning that it won’t interfere with other builds running simultaneously. This isolation is particularly important for complex pipelines with dependencies that could conflict with one another.

### Your Pipeline Example Explained:

```groovy
pipeline {
    agent {
        docker {
            image 'abhishekf5/maven-abhishek-docker-agent:v1'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    stages {
        stage('Checkout') {
            steps {
                sh 'echo passed'
            }
        }
    }
}
```

1. Jenkins pulls the `abhishekf5/maven-abhishek-docker-agent:v1` image and spins up a container with the specified arguments.
2. The `sh 'echo passed'` command runs inside the Docker container.
3. Once all stages are executed, the container is automatically removed.

### Conclusion

Yes, your understanding is correct! The `agent` is used to spin up a Docker container for running pipeline steps in an isolated environment, and once the pipeline is done, Jenkins removes the container. This method is a core part of Jenkins' flexibility for managing pipelines in consistent and reproducible environments.