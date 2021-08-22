FROM    ubuntu:21.10
ARG DEBIAN_FRONTEND="noninteractive"
# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456
# Make sure the dependencies are met
RUN apt update \
	&& apt install -y tigervnc-standalone-server fluxbox xterm git net-tools python python-numpy scrot wget software-properties-common vlc module-init-tools avahi-daemon \
	&& sed -i 's/geteuid/getppid/' /usr/bin/vlc \
	&& add-apt-repository ppa:obsproject/obs-studio \
	&& git clone --branch v1.0.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch v0.8.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
# Copy various files to their respective places
	&& wget -q -O /opt/container_startup.sh https://raw.githubusercontent.com/Daedilus/docker-obs-ndi/master/container_startup.sh \
	&& wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/Daedilus/docker-obs-ndi/master/x11vnc_entrypoint.sh \
	&& mkdir -p /opt/startup_scripts \
	&& wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/Daedilus/docker-obs-ndi/master/startup.sh \
	&& wget -q -O /tmp/libndi4_4.5.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/libndi4_4.5.1-1_amd64.deb \
	&& wget -q -O /tmp/obs-ndi_4.9.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/obs-ndi_4.9.1-1_amd64.deb 
# Update apt for the new obs repository
RUN apt update \
	&& mkdir -p /config/obs-studio /root/.config/ \
	&& ln -s /config/obs-studio/ /root/.config/obs-studio \
	&& apt install -y obs-studio \
	&& apt-get clean -y \
# Download and install the plugins for NDI
	&& dpkg -i /tmp/*.deb \
	&& rm -rf /tmp/*.deb \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/*.zip \
	&& wget -q -O /tmp/streamfx-ubuntu-20.04-0.10.1.0-gc8484f65.zip https://github.com/Xaymar/obs-StreamFX/releases/download/0.10.1/streamfx-ubuntu-20.04-0.10.1.0-gc8484f65.zip \
	&& unzip /tmp/*.zip -d /config/obs-studio/ \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 
	 
# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker \
	&& echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
