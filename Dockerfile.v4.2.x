FROM ubuntu:20.04
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

ARG DEBIAN_FRONTEND=noninteractive
ARG OMADA_VER=4.2.8
ARG OMADA_TAR="Omada_SDN_Controller_v${OMADA_VER}_linux_x64.tar.gz"
ARG OMADA_URL="https://static.tp-link.com/2020/202012/20201211/${OMADA_TAR}"

# install omada controller (instructions taken from install.sh); then create a user & group and set the appropriate file system permissions
RUN \
  echo "**** Install Dependencies ****" &&\
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list &&\
  apt-get update &&\
  apt-get install --no-install-recommends -y gosu mongodb-org net-tools openjdk-8-jre-headless tzdata wget &&\
  rm -rf /var/lib/apt/lists/* &&\
  echo "**** Download Omada Controller ****" &&\
  cd /tmp &&\
  wget -nv ${OMADA_URL} &&\
  echo "**** Extract and Install Omada Controller ****" &&\
  tar zxvf ${OMADA_TAR} &&\
  rm ${OMADA_TAR} &&\
  cd Omada_SDN_Controller_* &&\
  mkdir /opt/tplink/EAPController -vp &&\
  cp bin /opt/tplink/EAPController -r &&\
  cp data /opt/tplink/EAPController -r &&\
  cp properties /opt/tplink/EAPController -r &&\
  cp webapps /opt/tplink/EAPController -r &&\
  cp keystore /opt/tplink/EAPController -r &&\
  cp lib /opt/tplink/EAPController -r &&\
  cp install.sh /opt/tplink/EAPController -r &&\
  cp uninstall.sh /opt/tplink/EAPController -r &&\
  ln -sf $(which mongod) /opt/tplink/EAPController/bin/mongod &&\
  chmod 755 /opt/tplink/EAPController/bin/* &&\
  echo "**** Cleanup ****" &&\
  cd /tmp &&\
  rm -rf /tmp/Omada_SDN_Controller* &&\
  echo "**** Setup omada User Account ****" &&\
  groupadd -g 508 omada &&\
  useradd -u 508 -g 508 -d /opt/tplink/EAPController omada &&\
  mkdir /opt/tplink/EAPController/logs /opt/tplink/EAPController/work &&\
  chown -R omada:omada /opt/tplink/EAPController/data /opt/tplink/EAPController/logs /opt/tplink/EAPController/work

COPY entrypoint-4.2.x.sh /entrypoint.sh

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 27001/udp 27002 29810/udp 29811 29812 29813
HEALTHCHECK --start-period=5m CMD wget --quiet --tries=1 --no-check-certificate -O /dev/null --server-response --timeout=5 https://127.0.0.1:8043/login || exit 1
VOLUME ["/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-cp","/opt/tplink/EAPController/lib/*:","com.tplink.omada.start.OmadaLinuxMain"]
