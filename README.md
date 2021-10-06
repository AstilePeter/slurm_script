# OVERVIEW
This repository is for installing slurm in master and slave computer. For the authentication purpose munge need to be installed on both the computers prior to slurm installation. In this repository there is information about
-How to create slurm and munge users with home directory and same uid and gid
-Installing munge and checking whether the munge is encrypted and decrypted
-Installing slurm on both the computers
-Creating and allowing required permission for files that is needed in the configuration file
-Creating configuration file on both the computers
-On the master node creating configuartion file for the slurmctld host and databse
-Enabling and starting the services
-on the slave node creating configuartion file for the slurmd

# SLURM INSTALLATION
First we need to install slurm and munge on master computers

## CREATING SLURM AND MUNGE USER
The slurm and munge users must be created in all the node and master computer with same Uid and Gid:
```
sudo groupadd -u 5500 groupname

sudo useradd -m username -u 5600 -g groupname

```
To check the group number and userid:

```
lslogins -u

id <username>
```

## MUNGE INSTALLATION
The munge should be installed in both computers and make sure the munge key is same on all the computers:


```
sudo apt install munge libmunge-dev libmunge2 rng-tools -y

sudo rngd -r /dev/urandom

sudo /usr/sbin/create-munge-key -r -f`

sudo sh -c  "dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key"

sudo chown munge: /etc/munge/munge.key

sudo chmod 400 /etc/munge/munge.key

sudo systemctl enable munge

sudo systemctl start munge

```
To check whether the munge is working:

```
munge -n -t 10 | ssh <usr details> unmunge

```
## SLURM INSTALLATION

```
mkdir slurm-tmp

cd slurm-tmp/

export VER=20.11.8

wget https://download.schedmd.com/slurm/slurm-$VER.tar.bz2

tar jxvf slurm-$VER.tar.bz2

cd slurm-$VER

./configure --prefix=/usr --sysconfdir=/etc/slurm --enable-pam --with-pam_dir=/lib/x86_64-linux-gnu/security/ --without-shared-libslurm

sudo apt install gcc gawk cmake

make

make contrib

sudo make install

cd ..

sudo mkdir /var/spool/slurm
sudo chown slurm:slurm /var/spool/slurm
sudo chmod 755 /var/spool/slurm
sudo mkdir /var/spool/slurm/slurmctld
sudo chown slurm:slurm /var/spool/slurm/slurmctld
sudo chmod 755 /var/spool/slurm/slurmctld
sudo mkdir /var/spool/slurm/cluster_state
sudo chown slurm:slurm /var/spool/slurm/cluster_state
sudo touch /var/log/slurmctld.log
sudo chown slurm:slurm /var/log/slurmctld.log
sudo touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
sudo chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
sudo touch /var/run/slurmctld.pid /var/run/slurmd.pid
sudo chown slurm:slurm /var/run/slurmctld.pid /var/run/slurmd.pid
sudo mkdir -p /etc/slurm/prolog.d /etc/slurm/epilog.d 

```
Create a configuration file in the path /etc/slurm/slurm.conf on master and slave. When writing the configuration file make sure to change the hostname:

```
# slurm.conf file generated by configurator easy.html.
# Put this file on all nodes of your cluster.
# See the slurm.conf man page for more information.
#
SlurmctldHost=astile-desktop
#
#MailProg=/bin/mail
MpiDefault=none
#MpiParams=ports=#-#
ProctrackType=proctrack/cgroup
ReturnToService=2
SlurmctldPidFile=/var/run/slurmctld.pid
#SlurmctldPort=6817
SlurmdPidFile=/var/run/slurmd.pid
#SlurmdPort=6818
SlurmdSpoolDir=/var/spool/slurm/slurmd
SlurmUser=slurm
#SlurmdUser=root
StateSaveLocation=/var/spool/slurm/
SwitchType=switch/none
TaskPlugin=task/affinity
#
#
# TIMERS
#KillWait=30
#MinJobAge=300
#SlurmctldTimeout=120
#SlurmdTimeout=300
#
#
# SCHEDULING
SchedulerType=sched/backfill
SelectType=select/cons_res
SelectTypeParameters=CR_Core
#
#
# LOGGING AND ACCOUNTING
AccountingStorageType=accounting_storage/none
ClusterName=cluster
#JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
#SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurmctld.log
#SlurmdDebug=info
SlurmdLogFile=/var/log/slurmd.log
#
#
# COMPUTE NODES
NodeName=astile-desktop NodeAddr=192.168.1.104 CPUs=4 State=UNKNOWN
NodeName=test-desktop NodeAddr=192.168.1.101 CPUs=4 State=UNKNOWN
      

# PartitionName=test Nodes=$HOST Default=YES MaxTime=INFINITE State=UP
# PartitionName=test Nodes=$HOST,linux[1-32] Default=YES MaxTime=INFINITE State=UP
PartitionName=test Nodes=ALL Default=YES MaxTime=INFINITE State=UP

# DefMemPerNode=1000
# MaxMemPerNode=1000
# DefMemPerCPU=4000 
# MaxMemPerCPU=4096


```
Make another configuration file in /etc/slurm/cgroup.conf:

```
###
#
# Slurm cgroup support configuration file
#
# See man slurm.conf and man cgroup.conf for further
# information on cgroup configuration parameters
#--
CgroupAutomount=yes

ConstrainCores=no
ConstrainRAMSpace=no


```
Install mariaDB server:

```
sudo apt install mariadb-server libmariadbclient-dev libmariadb-dev -y


```
### ON THE MASTER NODE ONLY

Create another configurartion file in /etc/systemd/system/slurmctld.service:

```
[Unit]
Description=Slurm controller daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmctld
ExecStart=/usr/sbin/slurmctld $SLURMCTLD_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/slurmctld.pid

[Install]
WantedBy=multi-user.target


```
The configuration file for the database is as follows. It should be in the path /etc/systemd/system/slurmdbd.service:

```
[Unit]
Description=Slurm DBD accounting daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurmdbd.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmdbd
ExecStart=/usr/sbin/slurmdbd $SLURMDBD_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/slurmdbd.pid

[Install]
WantedBy=multi-user.target


```
Run the following commands in the master node:


```
sudo systemctl daemon-reload
sudo systemctl enable slurmdbd
sudo systemctl start slurmdbd
sudo systemctl enable slurmctld
sudo systemctl start slurmctld

```
### ON THE SLAVE NODE

Create a configuratiom file in /etc/systemd/system/slurmd.service:


```
[Unit]
Description=Slurm node daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmd
ExecStart=/usr/sbin/slurmd -d /usr/sbin/slurmstepd $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/slurmd.pid
KillMode=process
LimitNOFILE=51200
LimitMEMLOCK=infinity
LimitSTACK=infinity

[Install]
WantedBy=multi-user.target

```
Run the following commands:

```
sudo systemctl daemon-reload
sudo systemctl enable slurmd.service
sudo systemctl start slurmd.service

```
# IMPORTANT NOTES AND COMMANDS
- Make sure that the cgroup files in both the computers.

- If the nodes ever go down use the command given below:


```
sudo scontrol update nodename="astile-desktop" state=idle 
```
- To install stress job:
```
sudo apt install stress
```

