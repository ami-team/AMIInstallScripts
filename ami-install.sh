#!/bin/bash

########################################################################################################################
########################################################################################################################

BASE_PATH=/opt

########################################################################################################################

AMI_U=$(id -u -n)
AMI_G=$(id -g -n)

########################################################################################################################

JAVA_MS=2G
JAVA_MX=4G
JAVA_SS=20m

########################################################################################################################

TOMCAT_MAX_THREADS=200

########################################################################################################################

TOMCAT_SHUTDOWN_PORT=8005
TOMCAT_HTTPS_PORT=8443
TOMCAT_HTTP_PORT=8080

########################################################################################################################

TOMCAT_AJP_PORT=8009
TOMCAT_AJP_ADDRESS=$(curl -4 --silent icanhazip.com)
TOMCAT_AJP_SECRET=NOCgJx8ITYdHzdKF6asyrIFqq7dCcqmx3DCLRKUneEl91Xl2flRSnjeBmArS9Sbz

########################################################################################################################

TOMCAT_JVM_ROUTE=$(hostname -s)

########################################################################################################################

AWF=0
AWF_TITLE=AMI
AWF_ENDPOINT=https://localhost:8443/AMI/FrontEnd

########################################################################################################################
########################################################################################################################

while [[ $# -gt 0 ]]
do
  case $1 in
    -p|--base-path)
      BASE_PATH="$2"
      shift
      shift
      ;;
    -u|--user)
      AMI_U="$2"
      shift
      shift
      ;;
    -g|--group)
      AMI_G="$2"
      shift
      shift
      ;;
    --java-ms)
      JAVA_MS="$2"
      shift
      shift
      ;;
    --java-mx)
      JAVA_MX="$2"
      shift
      shift
      ;;
    --java-ss)
      JAVA_SS="$2"
      shift
      shift
      ;;
    --tomcat-max-threads)
      TOMCAT_MAX_THREADS="$2"
      shift
      shift
      ;;
    --tomcat-shutdown-port)
      TOMCAT_SHUTDOWN_PORT="$2"
      shift
      shift
      ;;
    --tomcat-https-port)
      TOMCAT_HTTPS_PORT="$2"
      shift
      shift
      ;;
    --tomcat-http-port)
      TOMCAT_HTTP_PORT="$2"
      shift
      shift
      ;;
    --tomcat-ajp-port)
      TOMCAT_AJP_PORT="$2"
      shift
      shift
      ;;
    --tomcat-ajp-address)
      TOMCAT_AJP_ADDRESS="$2"
      shift
      shift
      ;;
    --tomcat-ajp-secret)
      TOMCAT_AJP_SECRET="$2"
      shift
      shift
      ;;
    --tomcat-jvm-route)
      TOMCAT_JVM_ROUTE="$2"
      shift
      shift
      ;;
    --awf)
      AWF="$2"
      shift
      shift
      ;;
    --awf-title)
      AWF_TITLE="$2"
      shift
      shift
      ;;
    --awf-endpoint)
      AWF_ENDPOINT="$2"
      shift
      shift
      ;;
    --help)
      echo -e "Deploys an AMI Web Server from scratch.\n\n$0 --base-path \"${BASE_PATH}\" --user \"${AMI_U}\" --group \"${AMI_G}\" --java-ms \"${JAVA_MS}\" --java-mx \"${JAVA_MX}\" --java-ss \"${JAVA_SS}\" --tomcat-max-threads \"${TOMCAT_MAX_THREADS}\" --tomcat-shutdown-port \"${TOMCAT_SHUTDOWN_PORT}\" --tomcat-https-port \"${TOMCAT_HTTPS_PORT}\" --tomcat-http-port \"${TOMCAT_HTTP_PORT}\" --tomcat-ajp-port \"${TOMCAT_AJP_PORT}\" --tomcat-ajp-address \"${TOMCAT_AJP_ADDRESS}\" --tomcat-ajp-secret \"${TOMCAT_AJP_SECRET}\" --tomcat-jvm-route \"${TOMCAT_JVM_ROUTE}\" --awf \"${AWF}\" --awf-title \"${AWF_TITLE}\" --awf-endpoint \"${AWF_ENDPOINT}\"\n"
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

########################################################################################################################
########################################################################################################################

JAVA_HOME=${BASE_PATH}/java

AMI_HOME=${BASE_PATH}/AMI

########################################################################################################################
########################################################################################################################

if [[ $OSTYPE != 'darwin'* ]]
then
  JDK_URL=https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz
else
  JDK_URL=https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_osx-x64_bin.tar.gz
fi

########################################################################################################################

TOMCAT_URL=https://dlcdn.apache.org/tomcat/tomcat-10/v10.0.22/bin/apache-tomcat-10.0.22.tar.gz

########################################################################################################################
########################################################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

########################################################################################################################

function _line()
{
  echo -e "${BLUE}-----------------------------------------------------------------------------${NC}"
}

########################################################################################################################

function _box()
{
  _line
  echo -e "${BLUE}- $1${NC}"
  _line
}

########################################################################################################################

function _ok()
{
  echo -e "                                                                       [${GREEN}OKAY${NC}]"
  #### #
}

########################################################################################################################

function _err()
{
  echo -e "                                                                       [${RED}ERR.${NC}]"
  exit 1
}

########################################################################################################################
########################################################################################################################

_box "Downloading JDK"

(
  mkdir -p $JAVA_HOME
  cd $JAVA_HOME

  curl -L $JDK_URL > jdk.tar.gz

  if [[ $? -ne 0 ]]
  then
    _err
  fi

  DEST=$(tar tzf jdk.tar.gz | grep 'javac' | python3 -c "import os.path ; print(os.path.dirname(os.path.dirname(os.path.normpath(input()))))")

  rm -fr $DEST
  tar xzf jdk.tar.gz

  rm -fr current
  ln -s $DEST current

  rm jdk.tar.gz

) || _err

_ok

########################################################################################################################
########################################################################################################################

_box "Downloading Tomcat"

(
  mkdir -p ${AMI_HOME}
  cd ${AMI_HOME}

  curl -L $TOMCAT_URL > tomcat.tar.gz

  if [[ $? -ne 0 ]]
  then
    _err
  fi

  DEST=$(tar tzf tomcat.tar.gz | grep 'catalina.sh' | python3 -c "import os.path ; print(os.path.dirname(os.path.dirname(os.path.normpath(input()))))")

  rm -fr $DEST
  tar xzf tomcat.tar.gz

  rm -fr current
  ln -s $DEST current

  rm tomcat.tar.gz

) || _err

_ok

########################################################################################################################
########################################################################################################################

_box "Cleaning Tomcat"

(
  ###########################################################################

  cd ${AMI_HOME}/current

  ###########################################################################

  mv bin old
  mkdir bin

  cp old/bootstrap.jar old/catalina.sh old/setclasspath.sh old/tomcat-juli.jar bin

  rm -fr old

  ###########################################################################

  mv conf old
  mkdir conf

  cp old/catalina.policy old/catalina.properties old/context.xml old/logging.properties old/web.xml conf

  rm -fr old

  ###########################################################################

  rm -fr ${AMI_HOME}/current/webapps/*

  ###########################################################################

  chmod a+x ${AMI_HOME}/current/bin/catalina.sh

  ###########################################################################

) || _err

_ok

########################################################################################################################
########################################################################################################################

_box "Creating '${AMI_HOME}/current/conf/AMI.xml'"

cat > ${AMI_HOME}/current/conf/AMI.xml << EOF
<?xml version="1.0" encoding="ISO-8859-1"?>

<properties>
  <property name="base_url"><![CDATA[]]></property>

  <property name="admin_user"><![CDATA[]]></property>
  <property name="admin_pass"><![CDATA[]]></property>
  <property name="admin_email"><![CDATA[]]></property>

  <property name="encryption_key"><![CDATA[]]></property>
  <property name="authorized_ips"><![CDATA[]]></property>

  <property name="router_catalog"><![CDATA[]]></property>
  <property name="router_schema"><![CDATA[]]></property>
  <property name="router_url"><![CDATA[]]></property>
  <property name="router_user"><![CDATA[]]></property>
  <property name="router_pass"><![CDATA[]]></property>

  <property name="time_zone"><![CDATA[]]></property>

  <property name="class_path"><![CDATA[]]></property>
</properties>
EOF

_ok

########################################################################################################################
########################################################################################################################

_box "Creating '${AMI_HOME}/current/conf/server.xml'"

cat > ${AMI_HOME}/current/conf/server.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<Server port="${TOMCAT_SHUTDOWN_PORT}" shutdown="SHUTDOWN">

  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />

  <GlobalNamingResources>

  </GlobalNamingResources>

  <Service name="Catalina">

    <!--*************************************************************************************************************-->

    <Connector port="${TOMCAT_HTTPS_PORT}"
               protocol="org.apache.coyote.http11.Http11NioProtocol"
               connectionTimeout="20000"
               maxThreads="${TOMCAT_MAX_THREADS}"
               packetSize="65536"
               compression="on"
               SSLEnabled="true"
               scheme="https"
               secure="true">

        <SSLHostConfig certificateVerification="want"
                       truststoreFile="\${catalina.home}/conf/_star_.in2p3.fr.jks"
                       truststorePassword="changeit">

            <Certificate certificateKeystoreFile="\${catalina.home}/conf/_star_.in2p3.fr.jks"
                         certificateKeystorePassword="changeit" />

        </SSLHostConfig>

    </Connector>

    <!--*************************************************************************************************************-->

    <Connector port="${TOMCAT_HTTP_PORT}"
               redirectPort="${TOMCAT_HTTPS_PORT}"
               protocol="HTTP/1.1"
               connectionTimeout="20000"
               maxThreads="${TOMCAT_MAX_THREADS}"
               packetSize="65536" />

    <!--*************************************************************************************************************-->

    <Connector port="${TOMCAT_AJP_PORT}"
               redirectPort="${TOMCAT_HTTPS_PORT}"
               protocol="AJP/1.3"
               address="${TOMCAT_AJP_ADDRESS}"
               secret="${TOMCAT_AJP_SECRET}"
               secretRequired="true"
               allowedRequestAttributesPattern=".*"  
               connectionTimeout="20000"
               maxThreads="${TOMCAT_MAX_THREADS}"
               packetSize="65536" />

    <!--*************************************************************************************************************-->

    <Engine name="Catalina"
            defaultHost="localhost"
            jvmRoute="${TOMCAT_JVM_ROUTE}">

        <Host name="localhost"
              appBase="webapps"
              unpackWARs="true"
              autoDeploy="true">

            <Valve className="org.apache.catalina.valves.AccessLogValve"
                   directory="logs"
                   prefix="localhost_access_log"
                   suffix=".txt"
                   pattern="%h %l %u %t &quot;%r&quot; %s %b" />

        </Host>

    </Engine>

    <!--*************************************************************************************************************-->

  </Service>

</Server>
EOF

_ok

########################################################################################################################
########################################################################################################################

_box "Creating '${AMI_HOME}/current/bin/setenv.sh'"

cat > ${AMI_HOME}/current/bin/setenv.sh << EOF
JAVA_HOME=$JAVA_HOME/current

JAVA_OPTS='-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

CATALINA_OPTS='-Xms${JAVA_MS} -Xmx${JAVA_MX} -Xss${JAVA_SS} -server -XX:+UseParallelGC'
EOF

_ok

########################################################################################################################
########################################################################################################################

_box "Creating '${AMI_HOME}/current/bin/update_certs.sh'"

cat > ${AMI_HOME}/current/bin/update_certs.sh << PARENT_EOF
#!/bin/bash

JAVA_HOME=$JAVA_HOME/current

########################################################################################################################

THIS_SCRIPT=\${BASH_SOURCE[0]:-\$0}

while [[ -n \$(readlink \$THIS_SCRIPT) ]]
do
  THIS_SCRIPT=\$(readlink \$THIS_SCRIPT)
done

AMI_HOME=\$(cd \$(dirname \$THIS_SCRIPT) && pwd)/../conf

########################################################################################################################

BASE_URL=https://dist.igtf.net/distribution/current

########################################################################################################################

(
########################################################################################################################

rm -fr \${AMI_HOME}/certs
rm -fr \${AMI_HOME}/temp
mkdir -p \${AMI_HOME}/certs
mkdir -p \${AMI_HOME}/temp

########################################################################################################################

cd \${AMI_HOME}/temp

########################################################################################################################

version=\$(curl --silent \${BASE_URL}/version.txt)

version=\${version//[^0-9\.]}

curl --silent \\
     -o igtf-preinstalled-bundle-classic-\${version}.tar.gz \\
     -L \${BASE_URL}/accredited/igtf-preinstalled-bundle-classic-\${version}.tar.gz

########################################################################################################################

echo "Getting CA files (from IGTF version \${version}):"

########################################################################################################################

tar xzf igtf-preinstalled-bundle-classic-\${version}.tar.gz

########################################################################################################################

cat > _star_.in2p3.fr.b64 << EOF
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
uI+9iSpn4domatnCdu5OGeYZXEM8oxkYEQ==
EOF

base64 --decode _star_.in2p3.fr.b64 > \${AMI_HOME}/_star_.in2p3.fr.jks

########################################################################################################################

for file in *.pem
do
  echo -e " -> ${GREEN}\${file%.*}${NC}"

  hash=\$(openssl x509 -in \${file} -noout -hash)

  if [ \$? -eq 0 ]
  then
    cp \$file \${AMI_HOME}/certs/\${hash}.0

    echo "\${hash}: \${file%.*}" >> \${AMI_HOME}/certs/table.txt

    echo 'changeit' | \$JAVA_HOME/bin/keytool -noprompt -keystore \${AMI_HOME}/_star_.in2p3.fr.jks -importcert -alias \${hash} -file \${file} &> /dev/null

    if [ \$? -ne 0 ]
    then
      echo -e "${RED}    ** error **${NC}"
    fi
  else
    echo -e "${RED}    ** error **${NC}"
  fi
done

########################################################################################################################

chown -R ${AMI_U}:${AMI_G} \${AMI_HOME}

chmod -R 750 \${AMI_HOME}

########################################################################################################################

rm -fr \${AMI_HOME}/temp

########################################################################################################################
)

########################################################################################################################
PARENT_EOF

_ok

########################################################################################################################
########################################################################################################################

_box "Executing '${AMI_HOME}/current/bin/update_certs.sh'"

(
  chmod a+x ${AMI_HOME}/current/bin/update_certs.sh

  ${AMI_HOME}/current/bin/update_certs.sh

) || _err

_ok

########################################################################################################################
########################################################################################################################

_box "Downloading 'AMI.war'"

(
  curl -L http://ami.in2p3.fr/download/AMICoreWeb-1.0.0.war > ${AMI_HOME}/current/webapps/AMI.war

) || _err

_ok

########################################################################################################################
########################################################################################################################

if [[ $AWF == 1 ]]
then
  _box "Setuping AMI Web Framework (AWF)${NC}"

  (
    cd ${AMI_HOME}/current/webapps

    mkdir ROOT
    cd ROOT

    curl https://raw.githubusercontent.com/ami-team/AMIWebFramework/master/tools/awf_stub.py > awf.py

    cat > ext.json << EOF
{
	"packages": [
	]
}
EOF

    chmod a+x ./awf.py
    ./awf.py --update-prod
    ./awf.py --create-home-page -t "${AWF_TITLE}" -p "${AWF_ENDPOINT}"

  ) || _err

  _ok
else
  _box "Creating '${AMI_HOME}/current/webapps/ROOT/index.html'"

  (
    cd ${AMI_HOME}/current/webapps

    mkdir ROOT
    cd ROOT

    cat > index.html << EOF
<?xml version="1.0" encoding="UTF-8" ?>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta charset="utf-8" />

		<title>AMI is working!</title>
	</head>
	<body>

		AMI is working!

	</body>
</html>
EOF

  ) || _err

  _ok
fi

########################################################################################################################
########################################################################################################################

if [[ -d /etc/systemd/system/ && ${USER} == 'root' ]]
then
  _box "Creating '/etc/systemd/system/tomcat.service'"

  (
    cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=AMI Web Server
After=syslog.target network.target

[Service]
Type=forking

Environment='CATALINA_HOME=${AMI_HOME}/current'
Environment='CATALINA_BASE=${AMI_HOME}/current'

ExecStart=${AMI_HOME}/current/bin/catalina.sh start
ExecStop=${AMI_HOME}/current/bin/catalina.sh stop

User=${AMI_U}
Group=${AMI_G}

[Install]
WantedBy=multi-user.target
EOF

  ) || _err

  _ok
fi

########################################################################################################################
########################################################################################################################

_box "Executing 'chown -R ${AMI_U}:${AMI_G} ${AMI_HOME}'"

(
  chown -R ${AMI_U}:${AMI_G} ${AMI_HOME}

) || _err

_ok

########################################################################################################################
########################################################################################################################

_line

########################################################################################################################
########################################################################################################################
