FROM ubuntu:15.10
RUN apt-get -y update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y lxc perl-doc make gcc libxml2-dev zlib1g-dev
RUN echo yes | cpan
RUN cpan XML::LibXML \
	&& cpan Getopt::Long
VOLUME ["/opt/floday"]
WORKDIR /opt/floday/src
