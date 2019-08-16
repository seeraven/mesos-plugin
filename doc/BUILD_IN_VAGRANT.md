Build the Plugin in a Vagrant Machine
=====================================

Assuming you have a working vagrant setup (see vagrant/README.md), you can perform
the following steps to build and test the plugin.

In the following sections, we will assume that you have already started the virtual
machine by calling `vagrant up`. This will perform a provisioning that might fail
if you modified the sources.


Building the Plugin
-------------------

After a modification of the source files, you can build the plugin by calling:

```
vagrant ssh
cd mesos-plugin-mesos-* && mvn package -DskipTests
```

or as a one-line command to be executed from the host machine:

```
vagrant ssh -c "cd mesos-plugin-mesos-* && mvn package -DskipTests"
```

If you want to enable the unit tests, remove the `-DskipTests` option.


Testing the Plugin
------------------

To test the plugin, you can start Jenkins in the virtual machine by calling:

```
vagrant ssh
cd mesos-plugin-mesos-* && mvn hpi:run
```

or as a one-line command to be executed from the host machine:

```
vagrant ssh -c "cd mesos-plugin-mesos-* && mvn hpi:run"
```

Then you can access the Jenkins instance by opening
http://localhost:8090/jenkins/configure in the browser.
