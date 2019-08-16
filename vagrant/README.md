Helper Scripts for Virtual Machine managed by Vagrant
=====================================================

This directory contains helper scripts to provision the virtual machine
and start the jenkins server with the mesos plugin.


System Requirements
-------------------

  - vagrant (see https://www.vagrantup.com/downloads.html)
  - vagrant-proxyconf plugin (optional) installed with `vagrant plugin install vagrant-proxyconf`
  - VirtualBox (see https://www.virtualbox.org/)


Usage
-----

In the root directory of your repository clone, call

    vagrant up

This will download the virtual machine image, provisions it and builds the plugin.

To run the jenkins server in the virtual machine, execute the commands

    vagrant ssh
    cd mesos-plugin-mesos-*
    mvn hpi:run

Then you can connect to the Jenkins server of the virtual machine by opening
http://localhost:8090/jenkins/configure. Here you should configure the following
settings:

  - Mesos native library path:   `/usr/local/lib/libmesos.so`
  - Mesos Master url:            `zk://localhost:2181/mesos`
  - Jenkins URL:                 `http://127.0.0.1:8080/jenkins/`
  - Remote FS Root is NFS mount: No


Web Interface URLs
------------------

  - Jenkins: http://localhost:8090/jenkins
  - Mesos Master WebIfc:  http://localhost:8050/
  - Mesos Slave WebIfc:   http://localhost:8051/


Stopping the Virtual Machine
----------------------------

When you are finished, you can stop the virtual machine by calling

    vagrant destroy -f
