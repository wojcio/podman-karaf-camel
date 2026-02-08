FROM alpine:3.19

# Environment variables
ENV KARAF_VERSION=4.4.6
ENV CAMEL_VERSION=4.1.0
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Java, required packages, SSH server, and useful tools
RUN apk add --no-cache curl bash tar gzip wget unzip openjdk17-jdk openssh mc nano

# Download and install Apache Karaf 
RUN curl -fsSL "https://archive.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz" -o /tmp/karaf.tar.gz && \
    tar -xzf /tmp/karaf.tar.gz -C /opt && \
    mv "/opt/apache-karaf-${KARAF_VERSION}" /opt/karaf && \
    rm /tmp/karaf.tar.gz

ENV KARAF_HOME=/opt/karaf
ENV JAVA_MAX_MEM=2G
ENV JAVA_MIN_MEM=512M
ENV PATH="${KARAF_HOME}/bin:${PATH}"

# Setup non-root user
RUN addgroup -g 1000 karaf && \
    adduser -u 1000 -G karaf -s /bin/bash -D karaf && \
    chown -R karaf:karaf /opt/karaf

# Configure users and Web Console
RUN sed -i 's/^#karaf = karaf,_g_:admingroup/karaf = karaf,admin,ssh/g' ${KARAF_HOME}/etc/users.properties && \
    echo "root = admin,admin,ssh" >> ${KARAF_HOME}/etc/users.properties && \
    echo "org.osgi.service.http.port=8181" > ${KARAF_HOME}/etc/org.ops4j.pax.web.cfg && \
    echo "realm=karaf" > ${KARAF_HOME}/etc/org.apache.karaf.webconsole.cfg && \
    echo "role=admin" >> ${KARAF_HOME}/etc/org.apache.karaf.webconsole.cfg

# Set Linux root user password to amiga1200
RUN echo 'root:amiga1200' | chpasswd

# Configure SSH server for root login
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config && \
    ssh-keygen -A

# LTS Features Configuration
RUN cat > ${KARAF_HOME}/etc/org.apache.karaf.features.cfg << 'FEATURESCFG'
featuresRepositories = \
    mvn:org.apache.karaf.features/standard/4.4.6/xml/features, \
    mvn:org.apache.karaf.features/enterprise/4.4.6/xml/features, \
    mvn:org.apache.karaf.features/framework/4.4.6/xml/features, \
    mvn:org.apache.camel.karaf/apache-camel/4.4.3/xml/features

featuresBoot = \
    instance, \
    package, \
    log, \
    ssh, \
    framework, \
    system, \
    eventadmin, \
    feature, \
    shell, \
    management, \
    service, \
    war, \
    jaas, \
    deployer, \
    diagnostic, \
    wrap, \
    bundle, \
    config, \
    kar, \
    webconsole, \
    camel, \
    hawtio

featuresBootAsynchronous=false
autoRefresh=true
FEATURESCFG

WORKDIR ${KARAF_HOME}

# Expose standard SSH port for root access
EXPOSE 22 8101 8181 10099 44444

# Start SSH (background) and then Karaf (foreground)
# We switch to root to start SSHD, then su back to karaf for the server
USER root
CMD ["/bin/bash", "-c", "/usr/sbin/sshd && exec su - karaf -c '/opt/karaf/bin/karaf server'"]