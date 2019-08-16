#!/bin/bash -e
#
# Provisioning of the virtual machine to build and execute the jenkins mesos
# plugin.
#


# -----------------------------------------------------------------------------
# Helper for printing messages
# -----------------------------------------------------------------------------
function printMsg {
    echo "$(date +%H:%M:%S): $@"
}

function execCmd {
    if ! $@ &> /tmp/cmd_output.txt; then
	echo "Command $@ failed with return code $?!"
	echo "Output was:"
	echo "8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---"
	cat /tmp/cmd_output.txt
	echo "8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---8<---"
	exit 1
    fi
    rm -f /tmp/cmd_output.txt
}

# -----------------------------------------------------------------------------
# Gather system information
# -----------------------------------------------------------------------------
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
printMsg "Distribution $DISTRO found. Codename: $CODENAME"


# -----------------------------------------------------------------------------
# Copy apt overlay
# -----------------------------------------------------------------------------
printMsg "Copy apt overlay..."
execCmd cp -r /vagrant/vagrant/apt/* /etc/apt/
execCmd cp -a /vagrant/vagrant/apt/sources.list /etc/cloud/templates/sources.list.ubuntu.tmpl


# -----------------------------------------------------------------------------
# Add repository keys
# -----------------------------------------------------------------------------
for KEYFILE in /etc/apt/keys/*.key; do
    printMsg "Importing apt key $KEYFILE"
    execCmd apt-key add $KEYFILE
done


# -----------------------------------------------------------------------------
# Configure additional repositories
# -----------------------------------------------------------------------------
for REPOCONF in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    printMsg "Configuring repository configuration file $REPOCONF..."
    execCmd sed -i -e "s/\${DISTRO}/${DISTRO}/g" -e "s/\${CODENAME}/${CODENAME}/g" $REPOCONF
done


# -----------------------------------------------------------------------------
# Install helpers for version extraction
# -----------------------------------------------------------------------------
printMsg "Updating apt sources..."
execCmd apt-get -y update

printMsg "Installing libxml-xpath-perl..."
execCmd apt-get -y install libxml-xpath-perl


# -----------------------------------------------------------------------------
# Extract mesos version from pom.xml file
# -----------------------------------------------------------------------------
MESOS_VERSION=$(cat /vagrant/pom.xml | xpath -q -e /project/properties/mesos.version/text\(\) 2>/dev/null)


# -----------------------------------------------------------------------------
# Install java and maven
# -----------------------------------------------------------------------------
printMsg "Installing java and maven..."
execCmd apt-get -y --force-yes install openjdk-8-jdk-headless maven


# -----------------------------------------------------------------------------
# Install mesos
# -----------------------------------------------------------------------------
printMsg "Installing mesos version ${MESOS_VERSION}..."
execCmd apt-get -y install --force-yes --install-recommends mesos=${MESOS_VERSION}\*


# -----------------------------------------------------------------------------
# Configure mesos
# -----------------------------------------------------------------------------
printMsg "Configuring mesos..."
echo "TestCluster" > /etc/mesos-master/cluster
#echo "posix/cpu,posix/mem,gpu/nvidia" > /etc/mesos-slave/isolation
echo "mesos" > /etc/mesos-slave/containerizers


# -----------------------------------------------------------------------------
# Restart mesos
# -----------------------------------------------------------------------------
printMsg "Restarting mesos-master and mesos-slave"
execCmd service mesos-master restart
execCmd service mesos-slave restart


# -----------------------------------------------------------------------------
# Configure maven
# -----------------------------------------------------------------------------
printMsg "Configure maven to use cache on host..."
if [ ! -d /vagrant/.m2 ]; then
    mkdir /vagrant/.m2
    chown vagrant:vagrant /vagrant/.m2
fi
if [ ! -e /home/vagrant/.m2 ]; then
    ln -s /vagrant/.m2 /home/vagrant/.m2
fi

if [ -n ${http_proxy+x} ]; then
    printMsg "Configuring proxy for maven..."
    PROXY_HOST=$(echo $http_proxy | sed -E 's#.*://(.*):.*#\1#')
    PROXY_PORT=$(echo $http_proxy | sed -E 's#.*://.*:([0-9]*).*#\1#')
    printMsg " Proxy host: $PROXY_HOST"
    printMsg " Proxy port: $PROXY_PORT"

    cat > /home/vagrant/.m2/settings.xml <<EOF
<settings>
  <proxies>
    <proxy>
      <id>proxy</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>${PROXY_HOST}</host>
      <port>${PROXY_PORT}</port>
      <nonProxyHosts>${no_proxy}</nonProxyHosts>
    </proxy>
  </proxies>
  <profiles>
    <profile>
      <id>SUREFIRE-1588</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <properties>
        <argLine>-Djdk.net.URLClassPath.disableClassPathURLCheck=true</argLine>
      </properties>
    </profile>
  </profiles>
</settings>
EOF
else
    cat > /home/vagrant/.m2/settings.xml <<EOF
<settings>
  <profiles>
    <profile>
      <id>SUREFIRE-1588</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <properties>
        <argLine>-Djdk.net.URLClassPath.disableClassPathURLCheck=true</argLine>
      </properties>
    </profile>
  </profiles>
</settings>
EOF
fi
chown vagrant:vagrant /vagrant/.m2/settings.xml


# -----------------------------------------------------------------------------
# Acquire latest code (either from local source on host, or latest release
# download) of mesos-jenkins plugin.
# -----------------------------------------------------------------------------
MESOS_PLUGIN_VERSION="local"

if [ $MESOS_PLUGIN_VERSION = "local" ]; then
    if [ ! -d mesos-plugin-mesos-${MESOS_PLUGIN_VERSION} ]; then
        printMsg "Copy mesos-plugin sources..."
        execCmd mkdir -p mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}
        execCmd ln -s /vagrant/src mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}/src
        execCmd ln -s /vagrant/pom.xml mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}/pom.xml
        execCmd chown -R vagrant:vagrant mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}
    fi
else
    printMsg "Downloading mesos-jenkins ${MESOS_JENKINS_VERSION}..."
    execCmd wget https://github.com/jenkinsci/mesos-plugin/archive/mesos-${MESOS_PLUGIN_VERSION}.tar.gz
    execCmd tar -zxf mesos-${MESOS_PLUGIN_VERSION}.tar.gz && rm -f mesos-${MESOS_PLUGIN_VERSION}.tar.gz
    execCmd chown -R vagrant:vagrant mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}
fi


# -----------------------------------------------------------------------------
# Build plugin
# -----------------------------------------------------------------------------
printMsg "Building mesos-jenkins plugin"
# TODO(vinod): Update the mesos version in pom.xml.
su - vagrant -c "cd mesos-plugin-mesos-${MESOS_PLUGIN_VERSION} && mvn package -DskipTests"
printMsg "Done"


# -----------------------------------------------------------------------------
# Print final information
# -----------------------------------------------------------------------------
echo "****************************************************************"
echo "Successfully provisioned the machine."
echo "You can run the Jenkins server with plugin installed as follows:"
echo "> vagrant ssh"
echo "> cd mesos-plugin-mesos-${MESOS_PLUGIN_VERSION}"
echo "> mvn hpi:run"
echo "****************************************************************"
echo "NOTE: Configure the plugin as follows:"
echo "From local host go to http://localhost:8090/jenkins/configure"
echo "Mesos native library path: /usr/local/lib/libmesos.so"
echo "Mesos Master [hostname:port]: zk://localhost:2181/mesos"
echo "Mesos Master WebIfc:  http://localhost:8050/"
echo "Mesos Slave WebIfc:   http://localhost:8051/"
echo "Configure the JenkinsURL of the Mesos Slaves as:"
echo " http://127.0.0.1:8080/jenkins"
echo "****************************************************************"


# -----------------------------------------------------------------------------
# EOF
# -----------------------------------------------------------------------------
