FROM sharelatex/sharelatex
MAINTAINER filip.krikava@inria.fr

# install full latex
RUN tlmgr install scheme-full

# override the default
ADD nginx-sharelatex.conf /etc/nginx/sites-enabled/sharelatex.conf
