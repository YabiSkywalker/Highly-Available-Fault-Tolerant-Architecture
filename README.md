Greetings Reader! 

The information below is a guide to my terraform scripts that enable an AWS customer to have a highly available and fault tolerant cloud architecture centralized around EC2 instances, and Aurora for the database. 

The files are broken down as follows: 

    1. Cloning my repo will not allow you to deploy directly to your AWS account. You MUST connect your AWS account with your computer via a an IAM role. For security purposes, use the principal of least privilege. 
    2. main.tf are where the resources themselves are provisioned. Ex: All of the "resource" tags equate to a cloud resource, which is then followed by the kind of resource. 
    3. provider.tf is where you will find that I am pointing to the "us-east-2" region as it is the closest region to me. Since this is for demonstration purposes, I designed my architecture in a single region with a multi-az configuration. 
    4. variables.tf is where you will find my commonly used tags. I constantly reuse these as a provision resources within the main.tf script. 



For Continuous Integration, and Continuous Deployment install Jenkins on your local machine and attach the same IAM role to the Jenkins agent. 

    The Jenkins job this triggers will deploy all the changes in the following stages: 

        1. Terraform initalize 
        2. Terraform plan 
        3. Terraform apply 
        4. Terraform destroy (So we do not add unwanted costs.) 


