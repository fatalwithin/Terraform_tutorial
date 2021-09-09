# Terraform, AWS, Gitlab notes

## Terraform resource vs data

**Data sources** are to be considered read-only, they are used as a way to **pull** information about the outside world into the configuration - example: maybe you need to know an ip address for a DNS name and use it in a security group rule.

**Changes** will only ever be made to entities defined as **resources**, and that will happen during an “apply” if the managed entities are not in the state described by the resources definitions and the variables.

<u>You should not define a data sources for an entity described by a resources definition in the same configuration</u> (remember that you can have multiple configurations in different folders and they are totally independent of each other)

So you will use the configuration (the collection of script files and variables) to create everything the first time and also to maintain it over time. It is quite common that resource definitions are added to the configuration as the deployment evolves and Terraform will handle this quite well and just add the new resources and update the existing ones as and when needed.

## How to manage secrets and other sensitive data in Terraform code

The code example:

```json
resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "example"
  # How should you manage the credentials for the master user?
  username = "???"
  password = "???"
}
```



Even encrypted secrets may end up in `terraform.tfstate` in plain text (even if you mark them as sensitive explicitely it only helps keep them out of your logs ).

Workarounds:

1. **Store Terraform state in a backend that supports encryption**. Instead of storing your state in a local `terraform.tfstate` file, Terraform natively supports a variety of [backends](https://www.terraform.io/docs/backends/index.html), such as S3, GCS, and Azure Blob Storage. 
2. **Strictly control who can access your Terraform backend**. Since Terraform state files may contain secrets, you’ll want to carefully control who has access to the backend you’re using to store your state files. For example, if you’re using S3 as a backend, you’ll want to configure an IAM policy that solely grants access to the S3 bucket for production to a small handful of trusted devs (or perhaps solely just the CI server you use to deploy to prod).



### Environment variables

To use this technique, declare variables for the secrets you wish to pass in:

```json
variable "username" {
  description = "The username for the DB master user"
  type        = string
}variable "password" {
  description = "The password for the DB master user"
  type        = string
}
```

Next, pass the variables to the Terraform resources that need those secrets:

```json
resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "example"  # Set the secrets from variables
  username             = var.username
  password             = var.password
}
```

You can now pass in a value for each variable `foo` by setting an environment variable called `TF_VAR_foo`. For example, here’s how you could set `username` and `password` via environment on Linux, Unix, or Mac, and run `terraform apply` to deploy the database:

```json
# Set secrets via environment variables
export TF_VAR_username=(the username)
export TF_VAR_password=(the password)

# When you run Terraform, it'll pick up the secrets automatically
terraform apply
```

**Advantages of this technique**

- Keep plain text secrets out of your code and version control system.
- Easy solution to get started with.
- Integrates with most other secrets management solutions: e.g., if your company already has a way to manage secrets, you can typically find a way to make it work with environment variables.
- Test friendly: when writing tests for your Terraform code (e.g., with [Terratest](https://terratest.gruntwork.io/)), there are no dependencies to configure (e.g., secret stores), as you can easily set the environment variables to mock values.

**Drawbacks to this technique**

- Not everything is defined in the Terraform code itself. This makes understanding and maintaining the code harder.
- Everyone using your code has to know to take extra steps to either manually set these environment variables or run a wrapper script.
- No guarantees or opinions around security. Since all the secrets management happens outside of Terraform, the code doesn’t enforce any security properties, and it’s possible someone is still managing the secrets in an insecure way (e.g., storing them in plain text).

### Encrypted Files (e.g., KMS, PGP, SOPS)

The second technique relies on encrypting the secrets, storing the cipher text in a file, and checking that file into version control.

## An example using AWS KMS

Here’s an example of how you can use a key managed by AWS KMS to encrypt secrets. First, create a file called `db-creds.yml` with your secrets:

```json
username: admin
password: password
```

*Note: do NOT check this file into version control!*

Next, encrypt this file by using the `aws kms encrypt` command and writing the resulting cipher text to `db-creds.yml.encrypted`:

```bash
aws kms encrypt \
  --key-id <YOUR KMS KEY> \
  --region <AWS REGION> \
  --plaintext fileb://db-creds.yml \
  --output text \
  --query CiphertextBlob \
  > db-creds.yml.encrypted
```

You can now safely check `db-creds.yml.encrypted` into version control.

To decrypt the secrets from this file in your Terraform code, you can use the `aws_kms_secrets` data source (for GCP KMS or Azure Key Vault, you’d instead use the `google_kms_secret` or `azurerm_key_vault_secret` data sources, respectively):

```json
data "aws_kms_secrets" "creds" {
  secret {
    name    = "db"
    payload = file("${path.module}/db-creds.yml.encrypted")
  }
}
```

The code above will read `db-creds.yml.encrypted` from disk and, assuming you have permissions to access the corresponding key in KMS, decrypt the contents to get back the original YAML. You can parse the YAML as follows:

```json
locals {
  db_creds = yamldecode(data.aws_kms_secrets.creds.plaintext["db"])
}
```

And now you can read the `username` and `password` from that YAML and pass them to the `aws_db_instance` resource:

```json
resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "example"  # Set the secrets from the encrypted file
  username = local.db_creds.username
  password = local.db_creds.password
}
```

### Secret Stores (e.g., Vault, AWS Secrets Manager)

The third technique relies on storing your secrets in a dedicated *secret store*: that is, a database that is designed specifically for securely storing sensitive data and tightly controlling access to it.





### Conclusion

Here are your key takeaways from this blog post:

1. Do not store secrets in plain text.
2. Use a Terraform backend that supports encryption.
3. Use environment variables, encrypted files, or a secret store to securely pass secrets into your Terraform code. See the table below for the trade- offs between these options.

![img](https://miro.medium.com/max/60/1*aDyCJtV5h_zUd6salfUrxg.png?q=20)

![img](https://miro.medium.com/max/1400/1*aDyCJtV5h_zUd6salfUrxg.png)

Trade-offs between different options for securely managing secrets with Terraform

## Store sensitive data in GitLab CI/CD Variable

When GitLab creates a CI/CD pipeline, it will send all variables to the corresponding runner and the variables will be set as environment variables for the duration of the job. In particular, the values of **file** variables are stored in a file and the environment variable will contain the path to this file.

Start by showing the SSH private key:

```bash
cat ~/.ssh/id_rsa
```

Copy the output to your clipboard. Make sure to add a linebreak after `-----END RSA PRIVATE KEY-----`:

~/.ssh/id_rsa

```bash
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

Now navigate to **Settings** > **CI / CD** > **Variables** in your GitLab project and click **Add Variable**. Fill out the form as follows:

- Key: `ID_RSA`
- Value: Paste your SSH private key from your clipboard (including a line break at the end).
- Type: **File**
- Environment Scope: **All (default)**
- Protect variable: **Checked**
- Mask variable: **Unchecked**

**Note:** The variable can’t be masked because it does not meet the regular expression requirements (see [GitLab’s documentation about masked variables](https://gitlab.com/help/ci/variables/README#masked-variables)). However, the private key will never appear in the console log, which makes masking it obsolete.

A file containing the private key will be created on the runner for each CI/CD job and its path will be stored in the `$ID_RSA` environment variable.

Create another variable with your server IP. Click **Add Variable** and fill out the form as follows:

- Key: `SERVER_IP`
- Value: `your_server_IP`
- Type: **Variable**
- Environment scope: **All (default)**
- Protect variable: **Checked**
- Mask variable: **Checked**

Finally, create a variable with the login user. Click **Add Variable** and fill out the form as follows:

- Key: `SERVER_USER`
- Value: `deployer`
- Type: **Variable**
- Environment scope: **All (default)**
- Protect variable: **Checked**
- Mask variable: **Checked**



Add this to your `.gitlab-ci.yml` file:

.gitlab-ci.yml

```yml
. . .
variables:
  TAG_LATEST: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_NAME:latest
  TAG_COMMIT: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_NAME:$CI_COMMIT_SHORT_SHA
```

[The variables section](https://docs.gitlab.com/ee/ci/yaml/#variables) defines environment variables that will be available in the context of a job’s `script` section. These variables will be available as usual Linux environment variables; that is, you can reference them in the script by prefixing with a dollar sign such as `$TAG_LATEST`. GitLab creates some predefined variables for each job that provide context specific information, such as the branch name or the commit hash the job is working on (read more about [predefined variable](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)). Here you compose two environment variables out of predefined variables. They represent:

- `CI_REGISTRY_IMAGE`: Represents the URL of the container registry tied to the specific project. This URL depends on the GitLab instance. For example, registry URLs for [gitlab.com](https://gitlab.com/) projects follow the pattern: `registry.gitlab.com/your_user/your_project`. But since GitLab will provide this variable, you do not need to know the exact URL.
- `CI_COMMIT_REF_NAME`: The branch or tag name for which project is built.
- `CI_COMMIT_SHORT_SHA`: The first eight characters of the commit revision for which the project is built.

`$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_NAME` specifies the Docker image base name. According to [GitLab’s documentation](https://gitlab.com/help/user/packages/container_registry/index#build-and-push-images-from-your-local-machine), a Docker image name has to follow this scheme:

```
image name scheme<registry URL>/<namespace>/<project>/<image>
```

Next, add the following to your `.gitlab-ci.yml` file:

```yml
. . .
publish:
  image: docker:latest
  stage: publish
  services:
    - docker:dind
  script:
    - docker build -t $TAG_COMMIT -t $TAG_LATEST .
    - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY
    - docker push $TAG_COMMIT
    - docker push $TAG_LATEST
```

The `publish` section is the first [job](https://docs.gitlab.com/ee/ci/yaml/#introduction) in your CI/CD configuration. Let’s break it down:

- `image` is the Docker image to use for this job. The GitLab runner will create a Docker container for each job and execute the script within this container. `docker:latest` image ensures that the `docker` command will be available.
- `stage` assigns the job to the `publish` stage.
- `services` specifies Docker-in-Docker—the `dind` service. This is the reason why you registered the GitLab runner in privileged mode.

[The `script` section](https://docs.gitlab.com/ee/ci/yaml/#script) of the `publish` job specifies the shell commands to execute for this job. The working directory will be set to the repository root when these commands will be executed.

- `docker build ...`: Builds the Docker image based on the `Dockerfile` and tags it with the latest commit tag defined in the variables section.
- `docker login ...`: Logs Docker in to the project’s container registry. You use the predefined variable `$CI_BUILD_TOKEN` as an authentication token. GitLab will generate the token and stay valid for the job’s lifetime.
- `docker push ...`: Pushes both image tags to the container registry.

Your complete `.gitlab-ci.yml` file will look like the following:

```yml
stages:
  - publish
  - deploy

variables:
  TAG_LATEST: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_NAME:latest
  TAG_COMMIT: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_NAME:$CI_COMMIT_SHORT_SHA

publish:
  image: docker:latest
  stage: publish
  services:
    - docker:dind
  script:
    - docker build -t $TAG_COMMIT -t $TAG_LATEST .
    - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY
    - docker push $TAG_COMMIT
    - docker push $TAG_LATEST

deploy:
  image: alpine:latest
  stage: deploy
  tags:
    - deployment
  script:
    - chmod og= $ID_RSA
    - apk update && apk add openssh-client
    - ssh -i $ID_RSA -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN $CI_REGISTRY"
    - ssh -i $ID_RSA -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "docker pull $TAG_COMMIT"
    - ssh -i $ID_RSA -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "docker container rm -f my-app || true"
    - ssh -i $ID_RSA -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "docker run -d -p 80:80 --name my-app $TAG_COMMIT"
  environment:
    name: production
    url: http://your_server_IP
  only:
    - master
```

Finally click **Commit changes** at the bottom of the page in GitLab to create the `.gitlab-ci.yml` file. Alternatively, when you have cloned the Git repository locally, commit and push the file to the remote.

## AWS EKS Managed Node Groups

You can also use Terraform to provision node groups using the [aws_eks_node_group resource](https://www.terraform.io/docs/providers/aws/r/eks_node_group.html). Once a Managed Node Group is provisioned, AWS will start to provision and configure the underlying resources, which includes the Auto Scaling Group and associated EC2 instances. These resources are not hidden and can be monitored or queried using the EC2 API or the AWS Console’s EC2 page.

To customize the underlying ASG, you can provide a launch template to AWS. This allows you to specify custom settings on the instances such as an AMI that you built with additional utilities, or a custom user-data script with different boot options. You can read more about it in [the official documentation](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html).

The only thing that is not supported with Launch Templates and Managed Node Groups is that you can’t use spot instances with Managed Node Groups.

What if you could completely get rid of the overhead of managing servers? The third and final option gives us exactly that with Fargate.

Note that while Fargate removes the need for you to actively manage servers as worker nodes, AWS will still provision and manage VM instances to run the scheduled workloads. As such, you still have Nodes with EKS Fargate, and you can view detailed information about the underlying nodes used by Fargate when you query for them using [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) with `kubectl get nodes`.

![img](https://miro.medium.com/max/1400/1*-V9VzANnS98fBaT391pjmA.png)

Summary of supported configurations for the three worker node types. Click for full image.

## How to inject GitLab CI variables into Terraform variables?

 I want to now automate the resource creation on AWS using GitLab CI / CD.

My plan is the following:

1. Write a .gitlab-ci-yml file
2. Have the terraform calls in the .gitlab-ci.yml file

In my .gitlab-ci.yml, I have access to the secrets like this:

```dart
- 'AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}' 
- 'AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}' 
- 'AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}'
```

How can I pipe it to my Terraform scripts?

### Method 1

You set

```yaml
job:
    stage: ...
    variables: 
        TF_VAR_SECRET1: ${GITLAB_SECRET}
```

or

```yaml
job:
    stage: ...
    script:
        - export TF_VAR_SECRET1=${GITLAB_SECRET}
```

in your CI job configuration and interpolate these. 

### Method 2

I would suggest trying the `AWS Profile`. You can add credentials to `~/.aws/credentials` file like

```ini
[myprofile]
aws_access_key_id     = anaccesskey
aws_secret_access_key = asecretkey
```

and then you can set environment variable `export AWS_PROFILE=myprofile`. Now, if you run terraform from this shell, it should pick credentials listed under `myprofile`.

Also, you can have you `AWS Provider` code as follows:

```bash
provider "aws" {
  profile = "myprofile"
  region  = "${var.region}"
}
```

In my experience, interacting with AWS using `profile` is easy and better than setting environment variables on each shell.

1. using env varibles in Mac:

```shell
$ export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"
$ export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"
$ terraform plan
```

2. using profile, `~/.aws/credentials`

```yaml
aws configure
AWS Access Key ID: yourID
AWS Secret Access Key: yourSecert
Default region name : aws-region
Default output format : env
```

## What is the difference between Terraform module and provider?

In Terraform, a **provider** is a plugin (an executable program) that maps from Terraform’s plan/apply lifecycle to real API requests to some specific backend API. The AWS provider, then, is the adapter layer that allows Terraform to make requests to the various AWS service endpoints. Without the AWS provider Terraform cannot interact with AWS at all.

Terraform **modules** are a way to factor out parts of your Terraform code into reusable portions that can be called from many different configurations. A good Terraform module will generally introduce an additional level of abstraction over what a provider offers in order to more easily meet a common use-case.

Internally the EKS module uses the AWS provider. In the Terraform module registry you can see [all of the resource types used by the EKS module 4](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/7.0.1?tab=resources); the ones whose names start with `aws_` are from the AWS provider and correspond to object types in the AWS management APIs.

## How to expose web apps on top of AWS EKS cluster with Terraform?

You can continue to use the nginx ingress if you want. For that you’d stick an NLB in front pointing at all of the worker nodes (to send the 443/80 traffic to nginx).

Equally you could use the AWS Loadbalancer Controller which creates ALBs. You could use that to point to your nginx ingress or directly to your services. Configuration is via ingress annotations, including setting the certificate details (stored in ACM - you can use Terraform to upload your own certificate if you don’t want to use the automatic Amazon ones).

You could use External DNS to control the DNS records (depending on the provider/system you are using) or Terraform.

One of the great things about both Kubernetes & AWS is there is so much choice and different ways to do things. One of the worst things is also there being so much choice!

As a result you might not find a guide/blog post/stackoverflow describing things the way you want to do it (or working to your requirements/limitations).

For us we provision the EKS cluster via Terraform and also use it to deploy Helm charts for both the applications and support systems (for us that includes External DNS, Cluster Autoscaler, AWS Loadbalancer Controller). We then let Kubernetes manage the ALBs (we don’t need any of the more advanced functionality that nginx might give us) and the DNS (we use Route53 which is supported by External DNS). But that is only one way of many you could set things up…

## An example of complete GitLab CI pipeline of deploying to Kubernetes using Helm

**tl;dr**

```yaml
Here is complete `.gitlab-ci.yaml` file for reference.

cache:
  untracked: true
  key: "$CI_BUILD_REF_NAME"
  paths:
    - vendor/

before_script:
  - mkdir -p /go/src/gitlab.example.com/librerio/
  - ln -s $PWD ${APP_PATH}
  - mkdir -p ${APP_PATH}/vendor
  - cd ${APP_PATH}

stages:
  - setup
  - test
  - build
  - release
  - deploy

variables:
  CONTAINER_IMAGE: ${CI_REGISTRY}/${CI_PROJECT_PATH}:${CI_BUILD_REF_NAME}_${CI_BUILD_REF}
  CONTAINER_IMAGE_LATEST: ${CI_REGISTRY}/${CI_PROJECT_PATH}:latest
  DOCKER_DRIVER: overlay2

  KUBECONFIG: /etc/deploy/config
  STAGING_NAMESPACE: app-stage
  PRODUCTION_NAMESPACE: app-prod

  APP_PATH: /go/src/gitlab.example.com/librerio/libr_files
  POSTGRES_USER: gorma
  POSTGRES_DB: test-${CI_BUILD_REF}
  POSTGRES_PASSWORD: gorma

setup:
  stage: setup
  image: lwolf/golang-glide:0.12.3
  script:
    - glide install -v
  artifacts:
    paths:
     - vendor/

build:
  stage: build
  image: lwolf/golang-glide:0.12.3
  script:
    - cd ${APP_PATH}
    - GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o release/app -ldflags '-w -s'
    - cd release
  artifacts:
    paths:
     - release/

release:
  stage: release
  image: docker:latest
  script:
    - cd ${APP_PATH}/release
    - docker login -u gitlab-ci-token -p ${CI_BUILD_TOKEN} ${CI_REGISTRY}
    - docker build -t ${CONTAINER_IMAGE} .
    - docker tag ${CONTAINER_IMAGE} ${CONTAINER_IMAGE_LATEST}
    - docker push ${CONTAINER_IMAGE}
    - docker push ${CONTAINER_IMAGE_LATEST}

test:
  stage: test
  image: lwolf/golang-glide:0.12.3
  services:
    - postgres:9.6
  script:
    - cd ${APP_PATH}
    - curl -o coverage.sh https://gist.githubusercontent.com/lwolf/3764a3b6cd08387e80aa6ca3b9534b8a/raw
    - sh coverage.sh

deploy_staging:
  stage: deploy
  image: lwolf/helm-kubectl-docker:v152_213
  before_script:
    - mkdir -p /etc/deploy
    - echo ${kube_config} | base64 -d > ${KUBECONFIG}
    - kubectl config use-context homekube
    - helm init --client-only
    - helm repo add stable https://kubernetes-charts.storage.googleapis.com/
    - helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
    - helm repo update
  script:
    - cd deploy/libr-files
    - helm dep build
    - export API_VERSION="$(grep "appVersion" Chart.yaml | cut -d" " -f2)"
    - export RELEASE_NAME="libr-files-v${API_VERSION/./-}"
    - export DEPLOYS=$(helm ls | grep $RELEASE_NAME | wc -l)
    - if [ ${DEPLOYS}  -eq 0 ]; then helm install --name=${RELEASE_NAME} . --namespace=${STAGING_NAMESPACE}; else helm upgrade ${RELEASE_NAME} . --namespace=${STAGING_NAMESPACE}; fi
  environment:
    name: staging
    url: https://librerio.example.com
  only:
  - master
```

## How to export terraform output to environment variables?

Terraform output file something like

```yaml
output "example1" {
  value = "hello"
}
```

instead of `hello` set anything or variable.

Terraform command will set value

```yaml
export EXAMPLE1='hello'
```

```sh
output "example1" {
  value = "hello"
}

output "example2" {
  value = <<EOT
Hello world
This is a multi-line string with 'quotes' in "it".
EOT
}
```

After applying that configuration, the command above produced the following output:

```sh
export EXAMPLE1='hello'
export EXAMPLE2='Hello world
This is a multi-line string with '\''quotes'\'' in "it".
'
```

I redirected the output to a file `env.sh` and then loaded it into my shell to confirm that the variables were usable:

```sh
$ terraform output -json | jq -r '@sh "export EXAMPLE1=\(.example1.value)\nexport EXAMPLE2=\(.example2.value)"' >env.sh
$ source env.sh 
$ echo $EXAMPLE1
hello
$ echo "$EXAMPLE2"
Hello world
This is a multi-line string with 'quotes' in "it".
```



## How to use Imagepullsecret in Helm3?

I use this setup and works fine.

In deployment.yaml

```yaml
spec:
	{{- with .Values.imagePullSecrets }}
		imagePullSecrets:
			{{- toYaml . | nindent 8 }}
	{{- end }}
		containers:
```

In values.yaml

```yaml
imagePullSecrets:
  - name: regcred
```

And create secret `regcred` manually using

```bash
$ kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

You can find detailed documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)



## How to use AWS ECR images with AWS EKS?

Detailed info is here: https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html

If you get any permission issues on pushing your image via AWS CLI - make sure your AWS CLI role has permission [AmazonEC2ContainerRegistryFullAccess](https://console.aws.amazon.com/iam/home?region=ap-southeast-1#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2FAmazonEC2ContainerRegistryFullAccess).



## How to make ALB Kubernetes Ingress Controller on Amazon EKS?

https://www.bogotobogo.com/DevOps/Docker/Docker-Kubernetes-ALB-Ingress-Controller-with-EKS.php

https://aws.amazon.com/ru/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/

 

## How to run Node.JS app with Helm on Kubernetes?

https://medium.com/@cloudegl/run-node-js-app-using-kubernetes-helm-bb87747785a

How to dockerize and deploy Node.JS app with Gitlab CI:

https://taylor.callsen.me/how-to-dockerize-a-nodejs-app-and-deploy-it-using-gitlab-ci/

https://docs.gitlab.com/ee/ci/docker/using_docker_build.html

 