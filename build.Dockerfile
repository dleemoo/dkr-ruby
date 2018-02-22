ARG   BASE_IMAGE
FROM $BASE_IMAGE

ARG RUBY_DOWNLOAD_URL
ARG RUBY_DOWNLOAD_SHA256
ARG BUILD_PACKAGES
ARG PACKAGES

MAINTAINER Leonardo Lobo Lima <dleemoo@gmail.com>

RUN set -ex \
  # install so packages - ruby compilation and common gems with native extensions
  && DEBIAN_FRONTEND=noninteractive apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
     $BUILD_PACKAGES \
     $PACKAGES \
  # download ruby
  && wget $RUBY_DOWNLOAD_URL -qO /tmp/ruby.tar.gz \
  && echo "$RUBY_DOWNLOAD_SHA256 /tmp/ruby.tar.gz" | sha256sum -c - \
  && mkdir -p /tmp/ruby \
  && tar xzf /tmp/ruby.tar.gz -C /tmp/ruby --strip-components=1 \
  # compile ruby
  && cd /tmp/ruby \
  && ac_cv_func_isnan=yes ac_cv_func_isinf=yes ./configure --without-tk --disable-install-doc --enable-shared 1>/dev/null \
  && make -j"$(getconf _NPROCESSORS_ONLN)" 1>/dev/null \
  && mkdir -p /usr/ruby-build \
  && make DESTDIR=/usr/ruby-build install 1>/dev/null \
  && make install 1>/dev/null
  
RUN set -ex \
  # do not generate gem docs by default
  && mkdir -p /usr/local/etc && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc \
  && GEM_HOME=/usr/gems gem install bundler

### RUN set -ex \
###   # remove temporary files
###   && rm -rf /tmp/ruby* \
###   && apt-get purge $REMOVE_PACKAGES -y \
###   && apt autoremove -y \
###   && apt-get clean \
###   && rm -rf /var/lib/apt/lists/*

CMD ["irb"]
