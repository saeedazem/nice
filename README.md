# Task 1: Infrastructure as Code

## Scenario

Deploy a simple web application using AWS CloudFormation or Terraform. The application should consist of an EC2 instance hosting a static website (html file showing "hello world").

## Requirements

- Define necessary networking components (VPC, Subnets, Security Groups).
- Use a configuration management tool like AWS CloudFormation or Terraform.
- Ensure proper tagging and IAM roles for security.

## Deliverables

- Share the code repository with your infrastructure code.
- Provide instructions for deploying and tearing down the infrastructure.

# Task 2: CI/CD Setup

## Scenario

Implement a basic CI/CD pipeline using Jenkins to automate the deployment of changes to your static website.

## Requirements

- Connect your code repository to Jenkins.
- Use Jenkins for building and deploying the website.
- Demonstrate a successful automated deployment.

## Deliverables

- Provide documentation on the CI/CD pipeline setup.

## Solution For Task 2

we will Deploy a Website from GitHub Repository to EC2 using CodeDeploy as the Deployment Service and Jenkins as the Pipeline.(take a look on screenshots screenshots/project-flow.png)

### EC2 Setup

1. **Create an EC2 Instance with all the required resources.**
2. Create an IAM role with the necessary policies (see [screenshot](screenshots/iam-role-policies.png)).

   **Policies to be Added:**
   - **AmazonEC2FullAccess**
   - **AmazonS3FullAccess**
   - **AWSCodeDeployFullAccess**
   - **AWSCodeDeployRole**

3. Add the IAM role to the EC2 instance.
4. Jenkins runs on port **8080 (Default).**
5. To allow traffic to these ports, modify the Inbound rules of EC2.
   - Select your **EC2 instance -> Choose Security** -> Scroll down to find Inbound Rules.
   - Click on a security group to open the rules page. Navigate to Inbound Rules and edit it (see [screenshot](screenshots/security-group-inboud-rules.png)).
   - Add Source to **Anywhere-IPv4** and add **0.0.0.0/0.**
   - Click on **Save.**
   - **Launch** the instance.

### EC2 Requirements

- Install git if you haven’t already:

    ```bash
    sudo yum install git
    ```

- code setup is at task1 code and by running terraform it will launch aws codedeploy.

### Jenkins Installation:
- **Navigate back to EC2 for the installation process.**

```
sudo yum update –y

sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo yum upgrade

sudo dnf install java-17-amazon-corretto -y

sudo yum install jenkins -y

sudo systemctl enable jenkins

sudo systemctl start jenkins

sudo systemctl status jenkins
```

- Connect to **http://<your_server_public_DNS>:8080** from your browser.
- Use the following command to unlock Jenkins.
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

```

- Click on **“Install Suggested Plugins”** to install all the necessary plugins.
- Follow the path to install other required plugins
**|** **Dashboard -> Manage Jenkins -> Plugins**

### Plugins Needed :

- **AWS CodeDeploy** (take a look on screenshot screenshots/codedeploy-plugin.png)

This plugin provides a **“post-build”** step for **AWS CodeDeploy**.
- Click on **“Install”**.
- Click on **“Restart Jenkins when installation is complete and no jobs are running”**, so that the necessary plugins are updated.

### Jenkins Setup:

- Click on **“New Item”**
- Give it a name and select **“Freestyle Project”**, then click on **OK** (take a look on screenshot screenshots/freestyle-project.png)
- Under Source Code Management, choose **“Git”** and provide your **repository URL** and the **Branch**.(take a look on screenshot screenshots/source-code-managment.png)
- Under Build Triggers select **“Poll SCM”** and under **Schedule** give the Cron Job value * * * * *
- This checks the build **“every minute”**.
- Under Post-build Actions select **“Deploy an application to AWS CodeDeploy”**.(take a look on screenshot screenshots/deploy-app-to-codedeploy.png)
- Fill out the **Application, Deployment Group** and **Configuration Names** for the CodeDeploy which we created in the previous steps.
- Give the desired AWS Region.
- Give your Bucket name for **S3 Bucket** and leave **S3 Prefix** blank if there’s no other folders inside the bucket.

- Click on Use **Access/Secret Keys** and enter it there.(take a look on screenshot screenshots/use-account-access-secret-key.png)
- Click on Save, to **save** the build.(take a look on screenshot screenshots/example-of-codedeploy-conf-in-jenkins-post-build-actions.png)

- Come back to Dashboard and click on **Build Now**.
- As we can see the build has been successfully executed.(take a look on screenshots screenshots/build-status.png, screenshots/build-console-output.png)
- If we **change the code in GitHub and commit the changes**, it triggers Jenkins then it pushes the changes to CodeDeploy. These changes are sent to EC2 server.(take a look on screenshots screenshots/build-console-output.png, screenshots/build-console-output-scm.png)
- The logs are sent to **S3 bucket** to which we have added it to CodeDeploy in Jenkins.(take a look on screenshot screenshots/s3-bucket-example.png)

- **So when ever you update the source code of your webpage in your GitHub repository, it will be triggered and gets automatically updated then it reverts back to your webpage.**