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

## Task 1: Solution

## Terraform installation:
To install the Terraform for your specific operating system refer to this documentation https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

## Architecting our application:
We want the application to be highly available. To achieve high availability we can launch our EC2 instances in multiple Availability zones. Furthermore, autoscaling scaling and load-balancing would be required to achieve high availability. To satisfy these requirements we will use the following architecture(see [screenshot](screenshots/nice-task1.webp)).

## Files Related To The Task

- main.tf:  will contain the main set of configuration for your module. 
- variables.tf: will contain the variable definitions for your module. When your module is used by others, the variables will be configured as arguments in the module block. Since all Terraform values must be defined, any variables that are not given a default value will become required arguments. Variables with default values can also be provided as module arguments, overriding the default value.
- index.html: is an HTML file that serves as the home page for a website. It's often the first file that visitors to a website will see. Usually, index.html is automatically opened when visitors enter the domain without specifying a specific file.
- server.sh: a shell script to the EC2 instance using the user data. The user data script runs only once at the time of the instance launch. This user data can be provided using the ‘user_data’ attribute. The user data script needs to be base64 encoded that’s why we are using the filebase64() function of the Terraform. The ${path.module} variable points towards the current path of the Terraform directory. In the same directory, I have created a user data script named server.sh
The EC2 user data script executes with the root permissions by default. Therefore we don’t need to add sudo.
- appspec.yml: defines the deployment processes for aws codedeploy in our project
it will help us with:
    - Map the source files in your application revision to their destinations on the instance.
    - Specify custom permissions for deployed files.
    - Specify scripts to be run on each instance at various stages of the deployment process (hooks).
The appspec.yaml is applicable whether doing blue/green or in-place deployment.
- run_apache.sh: a shell script used by appspec.yml as a hook for application start

## How To Run Terraform

- run the following shell command inside the terminal.
```
terraform init
```

This command will download the provider that you’ve specified in the main.tf file.
- After running the ‘terraform init’ command you will see that there is a new ‘.terraform’ hidden folder. This folder contains all the provider modules and configuration files. You should not make changes in this folder.
- You need to specify the AWS region, AWS access key and AWS secret key inside the provider block like the following.
```
provider "aws" {
  region     = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}
```

If you don’t want to hardcode the access key and secret key inside the Terraform file you can download the AWS CLI tool and configure the CLI tool using these keys. So at the runtime Terraform will dynamically get the keys from the ~/.aws/config file.

- To check whether you have any syntactical mistakes in your file you can run the following command.
```
terraform plan
```
This will also give you an overview of the resource that needs to be created, modified or destroyed.
- To deploy this Terraform configuration use the following command.
```
terraform apply
```

It will prompt you for confirmation so type yes, and press enter.

- After a few minutes, your infrastructure will be deployed successfully. When the deployment is finished you can see all of your resources through the AWS console. To access your web server copy the DNS name of your load balancer and paste it into the browser and you should see the following output. It may take some time for EC2 user data script to be executed completely so please wait a few seconds.(see [screenshot](screenshots/web-server-page.png))
- In case of any change in index.html file in github repository, codedeploy will automatically updates it in the running EC2's machines in our environment in aws.

## Terminate the Resources:

After provisioning the infrastructure, at some point, you may want to terminate all the resources that are created by the Terraform, to avoid a surprise bill from AWS. Terminating the resources is super easy in terraform. To terminate the resources use the following command and it will delete all the resources created by the Terraform.
```
terraform destroy
```

It will prompt you for confirmation so you need to type ‘yes’.



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

we will Deploy a Website from GitHub Repository to EC2 using CodeDeploy as the Deployment Service and Jenkins as the Pipeline.(see [screenshot](screenshots/project-flow.png))

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

- **AWS CodeDeploy** (see [screenshot](screenshots/codedeploy-plugin.png))

This plugin provides a **“post-build”** step for **AWS CodeDeploy**.
- Click on **“Install”**.
- Click on **“Restart Jenkins when installation is complete and no jobs are running”**, so that the necessary plugins are updated.

### Jenkins Setup:

- Click on **“New Item”**
- Give it a name and select **“Freestyle Project”**, then click on **OK** (see [screenshot](screenshots/freestyle-project.png))
- Under Source Code Management, choose **“Git”** and provide your **repository URL** and the **Branch**.(see [screenshot](screenshots/source-code-managment.png))
- Under Build Triggers select **“Poll SCM”** and under **Schedule** give the Cron Job value * * * * *
- This checks the build **“every minute”**.
- Under Post-build Actions select **“Deploy an application to AWS CodeDeploy”**.(see [screenshot](screenshots/deploy-app-to-codedeploy.png))
- Fill out the **Application, Deployment Group** and **Configuration Names** for the CodeDeploy which we created in the previous steps.
- Give the desired AWS Region.
- Give your Bucket name for **S3 Bucket** and leave **S3 Prefix** blank if there’s no other folders inside the bucket.

- Click on Use **Access/Secret Keys** and enter it there.(see [screenshot](screenshots/use-account-access-secret-key.png))
- Click on Save, to **save** the build.(see [screenshot](screenshots/example-of-codedeploy-conf-in-jenkins-post-build-actions.png))

- Come back to Dashboard and click on **Build Now**.
- As we can see the build has been successfully executed.(see [screenshot](screenshots/build-status.png), [screenshot](screenshots/build-console-output.png))
- If we **change the code in GitHub and commit the changes**, it triggers Jenkins then it pushes the changes to CodeDeploy. These changes are sent to EC2 server.(see [screenshot](screenshots/build-console-output.png), [screenshot](screenshots/build-console-output-scm.png))
- The logs are sent to **S3 bucket** to which we have added it to CodeDeploy in Jenkins.(see [screenshot](screenshots/s3-bucket-example.png))

- **So when ever you update the source code of your webpage in your GitHub repository, it will be triggered and gets automatically updated then it reverts back to your webpage.**
