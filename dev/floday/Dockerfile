FROM ubuntu:15.10
RUN apt-get -y update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y lxc perl-doc make gcc libxml2-dev zlib1g-dev
RUN echo yes | cpan
RUN cpan XML::LibXML \
	&& cpan Getopt::Long \
	&& cpan Test::Exception
ADD komodo.tar.gz /opt/komodo
ENV PERL5LIB=/opt/komodo
ENV PERL5DB="BEGIN {require q($PERL5LIB/perl5db.pl)}"
ENV PERLDB_OPTS="RemotePort=172.17.0.1:9000"
COPY keepalive.pl /opt
VOLUME ["/opt/floday"]
WORKDIR /opt/floday/src
