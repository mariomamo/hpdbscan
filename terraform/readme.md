
# Create cluster
In this folder there are two terraform scripts you can use to create a cluster on AWS or Azure.

## What is terraform
From [www.terraform.io](https://www.terraform.io/intro)
> HashiCorp Terraform is an infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version, reuse, and share. You can then use a consistent workflow to provision and manage all of your infrastructure throughout its lifecycle. Terraform can manage low-level components like compute, storage, and networking resources, as well as high-level components like DNS entries and SaaS features.

We decided to use terraform because in this way we don't take care about resource allocation and destruction on AWS (or Azure). When we need our resources up we run `terraform apply -auto-approve` and all specified resources will be created. When we don't need resources up anymore we run `terraform destroy -auto-approve` and in this way all resources created with `terraform apply -auto-approve` will be destroyed and no cost will be charged.

## AWS settings
If you want to use AWS with terraform you need to setup some informations like `aws_access_key_id` and `aws_secret_access_key`. For creating **access key id** and **secret access key** see [here](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html).
Once you have them download AWS CLI from [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure`.
You will be asked for access key id, secret access key, region and default output format. Insert your informations (you can keep default output format empty)

```bash
AWS Access Key ID [None]: <your_access_key_id>
AWS Secret Access Key [None]: <your_secret_access_key>
Default region name [None]: eu-west-1
Default output format [None]:
```
> eu-west-1 region is Ireland and usually it is the cheapest region. You have to check what is the cheapest region if you want save money.



After that configuration files for AWS will be created and you are ready for run terraform script on AWS.

You can see more information [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)



## Azure settings
Download Azure CLI from [here](https://docs.microsoft.com/it-it/cli/azure/install-azure-cli-windows?tabs=azure-cli) and run `az login`in your terminal. You will be redirected to Azure webpage for login and when you have done configuration files for Azure will be created. You are ready for run terraform script on Azure.

:warning:
==For our experiments we used AWS terraform script. Be careful if you use Azure terraform script because some configuration can be missing. If you receive this error **A process or daemon was unable to complete a TCP connection** it is probably because your firewall closed MPI ports, so you need to open them. Since we don't know what ports MPI use, for AWS we opened all ports both incoming and autgoing.==
 :warning:

## Create public and private key pair
In order to connect to your cluster you need a public and private key pair. You can create them with `ssh-keygen`.
```bash
$ ssh-keygen

Generating public/private rsa key pair.
Enter file in which to save the key (C:\Users\$User/.ssh/id_rsa): $project_folder\terraform\hpc
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in $project_folder\terraform\prova
Your public key has been saved in $project_folder\terraform\prova.pub
The key fingerprint is:
SHA256: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Rename your key as `hpc` (if you have choose another name) and Azure terraform script will work.
For AWS terraform script you need to open `variables.tf` file and paste your private key in `ec2_public_key` variable.

```json
variable  "ec2_public_key" {
	description  =  "EC2 public key"
	type  		 =  string
	default  	 =  "your_public_key_here"
}
```

## Start with terraform
Go into your provider folder and run these commands
```bash
terraform init
```

This command have to be executed **only  one time** for install your provider plugin.

### Create cluster
```bash
terraform apply -auto-approve
```

### Destroy cluster
```bash
terraform destroy -auto-approve
```

In both AWS and Azure folder there is a `tfm.bat` file, it is just a wrapper for -auto-approve command.
### Create cluster
```bash
tfm apply
```

### Destroy cluster
```bash
tfm destroy
```

# Set up cluster
### :one:Copy private keys on nodes
Move on project folder and execute these commands.
This command copy your local `hpc` private key inside `~/.ssh` folder of the master node.
```bash
scp -i hpc hpc <machine_user>@<master_public_ip>:~/.ssh/hpc
```

### :two:Login on master node
```bash
ssh -i <machine_user>@<master_public_ip>
```

### :three:Clone the repository containing MPI cluster script
This script containing some instruction for make MPI cluster working
```bash
git clone https://github.com/spagnuolocarmine/ubuntu-openmpi-openmp.git
cd ubuntu-openmpi-openmp
```

### :four:Generate the install script
```bash
source generateInstall.sh
```

### :five:Run install script
```bash
source install.sh
```

### :six:Change permissions for ssh key
```bash
chmod 600 ~/.ssh/hpc
```


### :seven:For each worker node run the install script from the master node
```bash
ssh -i ~/.ssh/hpc <machine_user>@<master_public_ip> 'bash -s' < install.sh
```

### :eight:Compile test program
```bash
mpicc test.c -o test
```

### :nine:Create hosts file
```bash
nano hosts
```

Write this inside it
```bash
<local_ip_master_node> slots=4
<local_ip_worker_node_1> slots=4
<local_ip_worker_node_2> slots=4
<local_ip_worker_node_3> slots=4
```
Slots depends on how CPUs have your machine, we are using **t3.2xlarge** aws machine, so we have 4 processors (8 with hyperthreading) for each node.

### :one::zero:Run test program
```bash
mpirun -np 16 --hostfile hosts ./test
```

## Make working MPI with C++
### Install needed libraries
We need these libraries gcc, g++, cmake and hdf5 on all nodes
```bash
ssh <machine_public_ip>
sudo apt install gcc g++ cmake libhdf5-serial-dev
```

## Compile program with cmake
```bash
cmake . && make
```

## For each worker node create folder project
```bash
ssh <worker_public_ip> 'mkdir /home/pcpc/hpdbscan'
```

## Copy compiled file on all worker nodes
```bash
scp hpdbscan <worker_public_ip>:/home/pcpc/hpdbscan/hpdbscan
```

## Download datasets
You can download datasets from these links:
* [bremen_small.h5](https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/bremenSmall.h5.h5)
* [iris.h5](https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data)
* [twitter_small.h5](https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/twitterSmall.h5.h5)
* [bremen.h5](https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/bremen.h5.h5) (big dataset)

## Download datasets on master node
Move to `/home/pcpc/hpdbscan/` and run
```bash
wget https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/bremenSmall.h5.h5
wget https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data
wget https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/twitterSmall.h5.h5
wget https://b2share.eudat.eu/api/files/189c8eaf-d596-462b-8a07-93b5922c4a9f/bremen.h5.h5
```

## Create dataset folder for each node
```bash
ssh <local_worker_node_ip> 'mkdir /home/pcpc/hpdbscan/datasets'
```

## Copy datasets on all worker nodes
```bash
scp bremen.h5 <local_worker_node_ip>:/home/pcpc/hpdbscan/datasets/bremen.h5
scp bremen_small.h5 <local_worker_node_ip>:/home/pcpc/hpdbscan/datasets/bremen_small.h5
scp iris.h5 1<local_worker_node_ip>:/home/pcpc/hpdbscan/datasets/iris.h5
scp twitter_small.h5 <local_worker_node_ip>:/home/pcpc/hpdbscan/datasets/twitter_small.h5
```

## Run program
```bash
mpirun --map-by node -np 16 --hostfile hosts hpdbscan/hpdbscan --input-dataset DBSCAN -i hpdbscan/datasets/bremen.h5 /usr/include/hdf5
```

## Copy the output log file on ubuntu user
```bash
sudo cp o.txt /home/o.txt
```

## Download log file
From your local pc
```bash
scp -i hpc <machine_user>@<master_public_ip>:/home/o.txt o.txt
```