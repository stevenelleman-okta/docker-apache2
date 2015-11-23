# docker-apache2

[![Docker Repository on Quay](https://quay.io/repository/scaleft/apache2/status "Docker Repository on Quay")](https://quay.io/repository/scaleft/apache2)

This is meant to be a "base" docker image for Apache2 based images.

## Building your child Dockerfile

```sh
FROM quay.io/scaleft/apache2

COPY 00-site.conf /conf/
```