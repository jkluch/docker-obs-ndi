FROM ubuntu:21.04
ARG DEBIAN_FRONTEND="noninteractive"
ARG STREAMFX_FILE="streamfx-ubuntu-20.04-0.10.1.0-gc8484f65.zip"
ARG STREAMFX_VERSION="0.10.1"
ARG NDI_FILE="libndi4_4.5.1-1_amd64.deb"
ARG NDI_DEP="libndi4_4.5.1-1_amd64.deb"
ARG NDI_VERSION="4.9.1"
# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

# Make sure the dependencies are met
RUN apt-get update \
	&& apt-get install -y tigervnc-standalone-server fluxbox xterm git net-tools python3 python3-numpy scrot wget software-properties-common vlc avahi-daemon \
	&& apt-get upgrade -y \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/*

#Don't know what this does
RUN sed -i 's/geteuid/getppid/' /usr/bin/vlc

# VNC stuff
RUN git clone --branch v1.1.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch v0.10.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html
# Install OBS
RUN add-apt-repository ppa:obsproject/obs-studio \
	&& apt-get update \
	&& apt-get install -y obs-studio \
	&& apt-get upgrade -y \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/*
	# && mkdir -p /config/obs-studio /root/.config/
	# && ln -s /config/obs-studio/ /root/.config/obs-studio \
	
# Download and install the plugins for NDI
RUN wget -q -O /tmp/$NDI_DEP https://github.com/Palakis/obs-ndi/releases/download/$NDI_VERSION/$NDI_DEP \
	&& wget -q -O /tmp/$NDI_FILE https://github.com/Palakis/obs-ndi/releases/download/$NDI_VERSION/$NDI_FILE
	&& dpkg -i /tmp/*.deb \
	&& rm -rf /tmp/*.deb \
	&& wget -q -O /tmp/$STREAMFX_FILE https://github.com/Xaymar/obs-StreamFX/releases/download/$STREAMFX_VERSION/$STREAMFX_FILE \
	&& unzip /tmp/*.zip -d /config/obs-studio/ \
	&& rm -rf /tmp/*.zip \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 

# Copy various files to their respective places	
ADD startup.sh /opt/startup_scripts/
ADD container_startup.sh /opt/
ADD x11vnc_entrypoint.sh /opt/

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker \
	&& echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
