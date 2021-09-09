# DevOps task

## Assignment
Create an AWS EKS cluster which is running two or more instances of two sample applications.

The sample applications source code can be found in directories sample-app1/ and sample-app2/ in the current repository. The applications are written in TypeScript running in Node.js environment.

### Subtasks
- [ ] Create AWS ECR registry using Terraform language which will be used for pushing docker images and pulling for AWS EKS cluster.
> Think of the authentication and logging in to the ECR registry which will be required in later subtasks.

- [ ] Create a Gitlab CI/CD pipeline which will build and push docker image containing bundled node.js sample applications into AWS ECR docker registry.
> The pipeline will be defined in .gitlab-ci.yaml in the current project. The environment variables for AWS_* related secrets could be hardcoded in the file & committed in repository for the task purposes.
> Node.js sample applications are easily build using commands `npm i` (in old npm versions `npm run prepare`) and can be started with `npm start` (or `node dist/index`).

- [ ] Create an AWS EKS cluster using Terraform language which will be accessible using kubectl command over AWS cli authentication.
> The EKS cluster will need to have created VPC and all the network related resources as well (e.g.: subnets, security groups etc.)

- [ ] Adjust Gitlab CI/CD pipeline to contain manual deployment job (button) for each sample application. This job will deploy a sample application of currently built and pushed docker image into the created kubernetes cluster.
> You can optionally use HELM charts or other template technology if needed.

- [ ] Adjust the kubernetes cluster, AWS resources and others to have services available publicly into the internet and write down the URL addresses into README.md file (or into the environment.url property of deployment job in .gitlab-ci.yaml).

---
## Requirements and notes
Terraform language can be optionally replaced with another technology, which does the same thing.

Kubernetes cluster, AWS provider and Gitlab are required technologies for the task.

You can use anything available on the internet, and documentation, your previous projects or any other inspiration. There is no limitations.

The structure (directory) of the repository is up to you. Try to do it the best you can.

You'll get your empty personal AWS account and the admin credentials to perform all changes live immediately.

The result of task will be sent as a single Merge Request in current repository. The reviewer will be your task assigner. Keep your git history clean and with sense to allow the reviewer approve it easily.

For the AWS resources, use the free tiers if possible or the smallest tier. Prevent high billing for task purposes.
