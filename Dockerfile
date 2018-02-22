ARG   BASE_IMAGE
FROM  dleemoo/ruby:2.3.0-1-build AS build-env

MAINTAINER Leonardo Lobo Lima <dleemoo@gmail.com>

FROM $BASE_IMAGE
COPY --from=build-env /usr/ruby-build /
COPY --from=build-env /usr/gems       /gems

ARG LIB_PACKAGES
ARG PACKAGES

RUN set -ex \
  # install so packages - ruby compilation and common gems with native extensions
  && DEBIAN_FRONTEND=noninteractive apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
     $PACKAGES \
     $LIB_PACKAGES \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  # do not generate gem docs by default
  && mkdir -p /usr/local/etc && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

CMD ["irb"]
