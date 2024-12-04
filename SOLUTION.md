# Solution

## What Has Been Done
1. The Python code has been modified:
    1.1. Readiness and liveness probe endpoints have been added.  
    1.2. Dependencies in the `requirements.txt` file have been updated.
2. Dockerfile has been created.
3. A Helm chart has been created in the `.helm` directory.
4. A simple script, `deploy.sh`, has been created to emulate the deployment pipeline.  
5. Simple CI pipeline to run python tests on any branch but master has been added to .github/workflows. It's just emulation.

##How to run

### Prerequisites
1. You need to install a Minikube cluster (it should also work on EKS/AKS with the NGINX ingress controller) with the metrics and ingress addons.  
2. Run a port-forward to be able to communicate with the API exposed via ingress:
    ```zsh
    kubectl port-forward -n kube-system service/ingress-nginx-controller 8080:80 -n ingress-nginx
    ```
3. Add a record to the `/etc/hosts` file with a fake FQDN (e.g., `127.0.0.1 tradebyte.test`).  
4. You need to be authorized against the container registry to push publicly available Docker images.  
5. Your `~/.kube/config` must be configured, and the proper context should be selected.

"Usage: $0 <image_name> $1 <image_tag> $3 <project_name> $4 <base_url> $5 <env>"

### Deploying
**Simply run the `deploy.sh` script with the following parameters:**  
1. `image_name` - Docker Hub repo name (e.g., `cardiffc/tradebyte`).  
2. `image_tag` - Tag of the new image.  
3. `project_name` - Name of the project.  
4. `base_url` - FQDN you want to use to expose application. (e.g. `tradebyte.test`)
4. `env` - Name of the environment (`dev` or `staging` or `prod`).

    Example:
    ```zsh
    ./deploy.sh cardiffc/tradebyte 1 tradebyte tradebyte.test dev
    ```

**It will:**  
1. Build and push Docker images using the provided image name and tag.  
2. Render the Helm chart.
3. Install the Helm chart to the Kubernetes cluster in a namespace named after the project, using the previously built Docker images for the provided environment.
4. Install simple redis instance. 

### What Could Have Been Done Better & some tradeoffs
1. For this test task, I have created secret with some values and commited to git. I'd never do so in the real life. In a real-world scenario, I would use an external secrets storage (like AWS SSM or HashiCorp Vault) and a Kubernetes operator to sync them.  
2. For this test task, I am using HTTP instead of HTTPS for the exposed application. In a real-world scenario, it should be HTTPS.  
3. The Helm chart could be further tuned to allow for Service Accounts,NetworkPolicies (if needed), and so on. This tuning could be done based on the real world requirements understanding.  
4. The `deploy.sh` script should be replaced with a proper CI/CD pipeline.  
5. It is preferable to use Redis as a managed service provided by AWS or any other cloud platform.
6. Authentication should be enabled in Redis, but further improvements to the Python code are needed.
7. Using Gunicorn with a Tornado worker should be considered, but further code improvements are needed.
