# Create a virtual environment with all tools installed
# ref: https://hub.docker.com/_/debian
FROM debian:latest AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN apt-get update -qq \
&& apt-get install -yq git wget libssl-dev build-essential cmake \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install swig
RUN apt-get update -qq \
&& apt-get install -yq libpcre3-dev automake bison \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN wget -q "https://github.com/swig/swig/archive/refs/tags/v4.0.2.tar.gz" -O swig-4.0.2.tar.gz \
&& tar xvf swig-4.0.2.tar.gz \
&& rm swig-4.0.2.tar.gz \
&& cd swig-4.0.2 \
&& ./autogen.sh \
&& ./configure --prefix=/usr \
&& make -j 4 \
&& make install \
&& cd .. \
&& rm -rf swig-4.0.2

# Install .NET SDK
# see: https://docs.microsoft.com/en-us/dotnet/core/install/linux-debian
RUN apt-get update -qq \
&& apt-get install -yq wget gpg apt-transport-https \
&& wget -q "https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb \
&& apt-get update -qq \
&& apt-get install -yq dotnet-sdk-3.1 dotnet-sdk-6.0 \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Trigger first run experience by running arbitrary cmd
RUN dotnet --info

# Add the library src to our build env
FROM env AS devel
WORKDIR /home/project
COPY . .

FROM devel AS build
RUN cmake --version
RUN cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --target all -v
RUN cmake --build build --target install -v

FROM build AS test
RUN cmake --build build --target test -v

# Test install rules
FROM env AS install_env
WORKDIR /home/sample
COPY --from=build /home/project/build/dotnet/packages/*.nupkg ./

FROM install_env AS install_devel
COPY ci/samples .

FROM install_devel AS install_build
RUN dotnet build

FROM install_build AS install_test
RUN dotnet run
