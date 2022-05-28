# Copy private keys on nodes
```bash
scp -i hpc hpc ubuntu@3.248.233.140:~/.ssh/hpc
```

# Login on master node
```bash
ssh -i "C:\Users\e-mario.offertucci\Desktop\e-mario.offertucci\progetti\terraform\HPC\hpc" ubuntu@34.240.83.109
```

# Clone the repository for MPI cluster
```bash
git clone https://github.com/spagnuolocarmine/ubuntu-openmpi-openmp.git
cd ubuntu-openmpi-openmp
```

# Generate the installing script
```bash
source generateInstall.sh
```

And when it have done
```bash
source install.sh
```

Quando ha finito, sul master node, fare questo.
In realtà non è nemmeno necessario.
```bash
sudo passwd pcpc
```

E mettere come password "root".

# Change permissions for ssh key
```bash
chmod 600 ~/.ssh/hpc
```

# For each WORKER instance run the install script from the MASTER node
```bash
ssh -i ~/.ssh/hpc ubuntu@172.31.22.218 'bash -s' < install.sh
ssh -i ~/.ssh/hpc ubuntu@172.31.23.45 'bash -s' < install.sh
ssh -i ~/.ssh/hpc ubuntu@172.31.30.7 'bash -s' < install.sh
```

# Compilare il file da eseguire
```bash
mpicc test.c -o test
```

# Creare il file hosts
```bash
nano hosts
```

Scriverci dentro
```bash
172.31.31.157 slots=4
172.31.22.218 slots=4
172.31.23.45 slots=4
172.31.30.7 slots=4
```

# Lanciare il programma
```bash
mpirun -np 16 --hostfile hosts ./test
```

# Per c++
## Installare gcc, g++, cmake e hdf5
```bash
sudo apt install gcc g++ cmake libhdf5-serial-dev
```

## Installarle anche sulle altre macchine
```bash
ssh 172.31.22.218 && sudo apt install gcc g++ cmake libhdf5-serial-dev
ssh 172.31.23.45 && sudo apt install gcc g++ cmake libhdf5-serial-dev
ssh 172.31.30.7 && sudo apt install gcc g++ cmake libhdf5-serial-dev
```

## Per qualche motivo si devono aggiungere queste librerie
```c++
#include <stdexcept>
#include <limits>
```

in ```include/cxxopts.h```

# Compilare con cmake
```bash
Git pull
Git pull origin main

cmake . && make
```

# Creare la folder del progetto in ogni nodo
```bash
ssh 172.31.22.218 'mkdir /home/pcpc/hpdbscan'
ssh 172.31.23.45 'mkdir /home/pcpc/hpdbscan'
ssh 172.31.30.7 'mkdir /home/pcpc/hpdbscan'
```

# Copiare il file compilato sugli altri nodi
```bash
scp hpdbscan 172.31.22.218:/home/pcpc/hpdbscan/hpdbscan
scp hpdbscan 172.31.23.45:/home/pcpc/hpdbscan/hpdbscan
scp hpdbscan 172.31.30.7:/home/pcpc/hpdbscan/hpdbscan
```

# Copia i dataset dal pc alla macchina
```bash
scp -i hpc datasets/bremen_small.h5 ubuntu@34.241.195.219:bremen_small.h5
scp -i hpc datasets/iris.h5 ubuntu@34.241.195.219:iris.h5
scp -i hpc datasets/twitter_small.h5 ubuntu@34.241.195.219:twitter_small.h5
```

# Sposta i file in /home/pcpc/hpdbscan/
```bash
sudo mv bremen_small.h5 /home/pcpc/hpdbscan/datasets/bremen_small.h5
sudo mv iris.h5 /home/pcpc/hpdbscan/datasets/iris.h5
sudo mv twitter_small.h5 /home/pcpc/hpdbscan/datasets/twitter_small.h5
```

# Creare la folder per i dataset in ogni nodo
```bash
ssh 172.31.22.218 'mkdir /home/pcpc/hpdbscan/datasets'
ssh 172.31.23.45 'mkdir /home/pcpc/hpdbscan/datasets'
ssh 172.31.30.7 'mkdir /home/pcpc/hpdbscan/datasets'
```

# Copia i dataset sugli altri nodi
```bash
scp bremen.h5 172.31.22.218:/home/pcpc/hpdbscan/datasets/bremen.h5
scp bremen.h5 172.31.23.45:/home/pcpc/hpdbscan/datasets/bremen.h5
scp bremen.h5 172.31.30.7:/home/pcpc/hpdbscan/datasets/bremen.h5

scp bremen_small.h5 172.31.22.218:/home/pcpc/hpdbscan/datasets/bremen_small.h5
scp bremen_small.h5 172.31.23.45:/home/pcpc/hpdbscan/datasets/bremen_small.h5
scp bremen_small.h5 172.31.30.7:/home/pcpc/hpdbscan/datasets/bremen_small.h5

scp iris.h5 172.31.22.218:/home/pcpc/hpdbscan/datasets/iris.h5
scp iris.h5 172.31.23.45:/home/pcpc/hpdbscan/datasets/iris.h5
scp iris.h5 172.31.30.7:/home/pcpc/hpdbscan/datasets/iris.h5

scp twitter_small.h5 172.31.22.218:/home/pcpc/hpdbscan/datasets/twitter_small.h5
scp twitter_small.h5 172.31.23.45:/home/pcpc/hpdbscan/datasets/twitter_small.h5
scp twitter_small.h5 172.31.30.7:/home/pcpc/hpdbscan/datasets/twitter_small.h5
```

# Eseguire il programma
```bash
mpirun -np 16 --hostfile hosts hpdbscan/hpdbscan --input-dataset DBSCAN -i hpdbscan/datasets/bremen.h5 /usr/include/hdf5
mpirun -np 16 --hostfile hosts hpdbscan/hpdbscan --input-dataset DBSCAN -i hpdbscan/datasets/bremen_small.h5 /usr/include/hdf5
mpirun --allow-run-as-root -np 1 ./hpdbscan --input-dataset DBSCAN -i datasets/bremen_small.h5 /usr/include/hdf5
```

# Test
On the MASTER node login in pcpc sudo login pcpc, password: root
Local login ssh localhost
Remote login on a worker node ssh IP
