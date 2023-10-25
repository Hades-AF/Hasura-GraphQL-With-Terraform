<br>

# Terraform Basic AWS Setup



### **Step One**

Firstly, we're going to want to make sure that we have everything to deploy our code.


-  [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- [PuTTY](https://www.putty.org/)

*NOTE - You will also want to make sure everything is setup in your environment variables.*

---

### **Step Two**

Secondly, we will want to associate our AWS with our local environment. This will require you to run [**aws configure**].

You will need the access key and secret key along with a few other details the CL will instruct you. These can be obtained from your AWS console.

### **Step Three**

You will want to generate a .pem security key called test-key. You can do this in EC2 key-pairs. Start up puttyGen and load the .pem key so that it generates a .ppk key.

### **Step Four**

Go ahead and clone this repository to your local machine. Update the main.tf and include your aws access and secret keys. Make sure your CL is in the root folder of this repository before running the terraform commmands.

These go as following:

- terraform init 
- terraform plan
- terraform apply --auto-approve

*NOTE - Once you are all done MAKE SURE to run [**terraform destroy**] so that you tear down the resources from AWS or else you will passively be build for them.

### **Step Five**

Go to your newly generated EC2 instance and check the IPV4 address that was associated with the Elastic IP. You will want to go this url and see if it gives you back a string of the following:

- basic web server test

### **Step Six**

Start-up regular PuTTY hostname should be ubuntu@(your-ipv4-ip). Then go to connection -> ssh -> auth -> credentials and browse for the ppk key.

From here you should be connected to the server, there is an issue with the file so you will want to rerun the commands from run_docker_compose resource in the main.tf file.

### All Done!