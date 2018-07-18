#! /bin/bash

set -ex

sles_image="suse/sles12sp3:2.0.2-with-repos"
nvidia_image="nvidia/cuda:9.1-cudnn7-devel"
cuda="cuda-9.1"

docker pull "${nvidia_image}"

docker build -f- \
	--build-arg http_proxy="${http_proxy}" \
	--build-arg https_proxy="${https_proxy}" \
	--build-arg no_proxy="${no_proxy}" \
	--network=host \
	-t libnvidia-container-sles-rpms . <<EOF
FROM ${sles_image}

WORKDIR /build
COPY . .

COPY --from=${nvidia_image} /usr/local/${cuda} /usr/local/${cuda}

RUN zypper ar https://download.opensuse.org/repositories/devel:/tools:/building/SLE_12_SP3 devel:tools:building ; \
	zypper -qn --gpg-auto-import-keys ref -s ; \
	zypper -qn in git make m4 which gcc curl tar bmake lsb-release groff libcap-devel libseccomp-devel patch rpm-build rpmlint python-xml

RUN touch /usr/bin/building ; \
	chmod +x /usr/bin/building ; \
	CFLAGS="-I/usr/include/libseccomp" make rpm CUDA_DIR=/usr/local/${cuda}
EOF

docker run -it --rm -v $(pwd):/pwd -u $(id -u):$(id -g) libnvidia-container-sles-rpms cp -a /build/dist /pwd/

# docker image rm "libnvidia-container-sles-rpms:latest"

