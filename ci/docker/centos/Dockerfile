# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/centos
FROM centos:latest AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN yum -y update \
&& yum -y install git wget openssl-devel \
&& yum -y groupinstall "Development Tools" \
&& yum clean all \
&& rm -rf /var/cache/yum
# Install CMake 3.16.4
RUN wget "https://cmake.org/files/v3.16/cmake-3.16.4-Linux-x86_64.sh" \
&& chmod a+x cmake-3.16.4-Linux-x86_64.sh \
&& ./cmake-3.16.4-Linux-x86_64.sh --prefix=/usr/local/ --skip-license \
&& rm cmake-3.16.4-Linux-x86_64.sh
# Install swig
FROM base AS swig
RUN yum -y update \
&& yum -y install pcre-devel \
&& yum clean all \
&& rm -rf /var/cache/yum \
&& wget "https://downloads.sourceforge.net/project/swig/swig/swig-4.0.1/swig-4.0.1.tar.gz" \
&& tar xvf swig-4.0.1.tar.gz \
&& rm swig-4.0.1.tar.gz \
&& cd swig-4.0.1 \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.0.1
# .NET install
# see https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-centos7
RUN rpm -Uvh "https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm" \
&& yum -y update \
&& yum -y install dotnet-sdk-3.1 \
&& yum clean all \
&& rm -rf /var/cache/yum
# Trigger first run experience by running arbitrary cmd
RUN dotnet --info
CMD [ "/usr/bin/bash" ]

FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake -S. -Bbuild
RUN cmake --build build --target all
RUN cmake --build build --target install

FROM build AS test
RUN cmake --build build --target test

FROM env AS install_env
WORKDIR /home/sample
COPY --from=build /home/project/build/dotnet/packages/*.nupkg ./

FROM install_env AS install_devel
COPY ci/samples .

FROM install_devel AS install_build
RUN dotnet build

FROM install_build AS install_test
RUN dotnet test
