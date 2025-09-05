#!/bin/bash
set -e
source bash-scripts/helpers.sh
if [ -z "$1" ]; then
	run_shfmt_and_shellcheck ./*.sh
fi
docker_configure
docker_setup "fsuae_build"
dockerfile_create
cat >>"$DOCKERFILE" <<'EOF'
RUN set -ex \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
	autoconf \
	automake \
	build-essential \
	gettext \
	libflac-dev \
	libfreetype6-dev \
	libglew-dev \
	libglib2.0-dev \
	libjpeg-dev \
	libmpg123-dev \
	libmpeg2-4-dev \
	libopenal-dev \
	libpng-dev \
	libsdl3-dev \
	libsdl3-image-dev \
	libsdl3-ttf-dev \
	libtool \
	libxi-dev \
	libxtst-dev \
	libportmidi-dev \
	python3-dev \
	zip \
	zlib1g-dev \
	git \
	ca-certificates \
	xz-utils \
	zip \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
RUN set -ex \
    && mkdir -p /release \
    && git clone https://github.com/FrodeSolheim/fs-uae.git \
    && tar cvJf /release/fs-uae.tar.xz fs-uae
RUN set -ex \
    && cd fs-uae \
    && bash ./bootstrap \
    && bash ./configure --prefix=$(realpath ../install) 2>&1 | tee ../release/configure.txt \
    && make -j $(nproc) \
    && make install
RUN set -ex \
    && cd install \
    && ls -al \
    && zip -r /release/fs-uae.zip ./*
EOF
docker_build_image_and_create_volume
docker run -d --name "$IMAGE_NAME" "$IMAGE_NAME" sleep 43200
docker cp "$IMAGE_NAME":/release ./
docker rm -f "$IMAGE_NAME" || true
