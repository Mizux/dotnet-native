# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/fedora
FROM fedora:latest AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget \
&& dnf -y groupinstall "Development Tools" \
&& dnf -y install gcc-c++ cmake \
&& dnf clean all
# Install swig
FROM base AS swig
RUN dnf -y update \
&& dnf -y install swig \
&& dnf clean all
# .NET install
# see: https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-fedora31
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
&& wget -q -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/fedora/31/prod.repo \
&& dnf -y update \
&& dnf -y install dotnet-sdk-3.1 \
&& dnf clean all
# Trigger first run experience by running arbitrary cmd
RUN dotnet --info
CMD [ "/usr/bin/bash" ]

FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake -S. -Bbuild
RUN cmake --build build --target all -v
RUN cmake --build build --target install

FROM build AS test
RUN cmake --build build --target test

FROM env AS install_env
WORKDIR /home/sample
COPY --from=build /home/project/build/dotnet/packages/*.nupkg ./

FROM install_env AS install_devel
COPY ci/samples/dotnet .

FROM install_devel AS install_build
RUN dotnet build

FROM install_build AS install_test
RUN dotnet test
