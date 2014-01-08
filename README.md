hadoop-salt
=

A saltstack.org wrapper project - this project just pulls all necessary components (formulas) into the right context

All the 'real' provisioning code is pulled into this scaffold as salt formulas using gitfs remote configuration on the master.
With this being the main principle (100% of the code and configuration live in external repositories) the saltmaster
itself can be dynamically provisioned as part of salt-cloud maps, thus providing the ability to run an arbitrary number
of clusters in different of identical topology and configuration in the same (or differnet) cloud provider account(s).

Salt Master Configuration
-

As this project has next to no code of its own, you'll need to configure your salt master to pull in the necessary formulas. Also notice that the generic pillar settings are pulled in as ext_pillar via gitfs - you can easily plug in your own settings instead.
Please see AWS_EXAMPLE.md for a full configuration example.

``Using Vagrant``
-

These are the steps to follow to a single-instance Centos 6 installation of Accumulo:

1. __Preparation__: Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](http://www.vagrantup.com/downloads.html) on your computer, clone this repository
2. __Configuration__: In the cloned project directory you'll find _configuration.yaml.example_ - you need a copy of this named configuration.yaml. Changes you make to the file will be available to the salt code. __You will need to review the file before using it!__
3. __Startup__: Run `vagrant up` - by default this will bring up a single CentOS 6 VM ready to run salt
4. Run the script `./go-salt.sh` in the project directory

`Options with Vagrant`

Besides the values in configuration.yaml, you have control over
The default number of nodes with the Vagrant file is currently 0 - you get one hadoop_master and slave in a standalone configuration.
Bring up the VMs with  `vagrant up`. There is currently no automated provisioning with Vagrant - you will have to login to the salt master (known to vagrant as namenode) with `vagrant ssh namenode` and (as root) run `salt '*' state.highstate`.
This entire mode of operation is for development only - if you are unfamiliar with Vagrant environments this is likely to be a challenge.

