FROM ubuntu:latest
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y aria2 openssh-server xrdp xfce4 xfce4-power-manager xfce4-terminal sudo htop tmux && apt-get clean
RUN mkdir /var/run/sshd
RUN adduser --disabled-password --gecos '' vagrant
RUN adduser vagrant sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R vagrant /home/vagrant
RUN echo 'vagrant:vagrant' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo "xfce4-session" > /home/vagrant/.xsession

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
USER vagrant
RUN cd /home/vagrant && aria2c -q "https://download.jetbrains.com/product?code=PC&latest&distribution=linux" && tar xf *.tar.gz && rm *.tar.gz
RUN cd /home/vagrant && aria2c -q "https://download.jetbrains.com/product?code=CL&latest&distribution=linux" && tar xf *.tar.gz && rm *.tar.gz
USER root
RUN cd /home/vagrant && aria2c -q "https://go.microsoft.com/fwlink/?LinkID=760868" && DEBIAN_FRONTEND="noninteractive" apt install ./*.deb && rm *.deb


RUN apt-get update \
  && apt-get install -y ssh \
      build-essential \
      gcc \
      g++ \
      gdb \
      clang \
      cmake \
      rsync \
      tar \
      python3 \
      python3-dev \
      python3-pip \
      software-properties-common \
      nodejs \
      git \
      npm \
  && add-apt-repository -y ppa:deadsnakes/ppa \
  && apt-get update \
  && apt-get -y install python3.5 python3.5-dev \
  && apt-get -y install python3.6 python3.6-dev \
  && apt-get clean
# For MCS
RUN apt-get -y install libboost-all-dev && apt-get clean
RUN python3.5 -m pip install numpy pandas scipy scikit-learn tensorflow==1.15 networkx==2.2 beautifulsoup4 lxml matplotlib seaborn colour pytz requests flask klepto
RUN python3.6 -m pip install numpy pandas scipy scikit-learn tensorflow==1.15 networkx==2.2 beautifulsoup4 lxml matplotlib seaborn colour pytz requests flask klepto
RUN pip3 install requests flask

# Fix Tensorflow error
COPY tensorflow_fix/flags.py /usr/local/lib/python3.6/dist-packages/tensorflow_core/python/platform/

# Setup Repo (you still need you manually train the models after starting the container though)
# In Graph-Hashing checkout mcs or server branch
USER vagrant
RUN cd /home/vagrant && git clone https://github.com/erdnase1902/vldb-demo-full.git && cd vldb-demo-full/ && git clone https://github.com/erdnase1902/Graph-Hashing.git && cd Graph-Hashing && git checkout server
RUN cd /home/vagrant/vldb-demo-full/flask_server/static && git clone https://github.com/jacomyal/sigma.js.git && cd sigma.js && npm install && npm run build
USER root
RUN ln -s /home/vagrant/vldb-demo-full /project
RUN chown vagrant /project


EXPOSE 22
EXPOSE 3389
EXPOSE 5000
EXPOSE 8000
EXPOSE 8080
EXPOSE 80
CMD ["/usr/sbin/sshd", "-D"]
