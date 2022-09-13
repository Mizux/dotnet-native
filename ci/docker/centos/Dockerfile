# Create a virtual environment with all tools installed
# ref: https://quay.io/repository/centos/centos
FROM quay.io/centos/centos:stream AS env
LABEL maintainer="mizux.dev@gmail.com"
# Install system build dependencies
ENV PATH=/usr/local/bin:$PATH
RUN dnf -y update \
&& dnf -y install git wget openssl-devel cmake \
&& dnf -y groupinstall "Development Tools" \
&& dnf clean all \
&& rm -rf /var/cache/dnf
CMD [ "/usr/bin/bash" ]

# Install SWIG 4.0.2
RUN dnf -y update \
&& dnf -y install pcre-devel \
&& dnf clean all \
&& rm -rf /var/cache/dnf \
&& wget -q "https://github.com/swig/swig/archive/refs/tags/v4.0.2.tar.gz" -O swig-4.0.2.tar.gz \
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
# see: https://docs.microsoft.com/en-us/dotnet/core/install/linux-centos
RUN dnf -y update \
&& dnf -y install dotnet-sdk-3.1 \
&& dnf clean all \
&& rm -rf /var/cache/dnf
# Trigger first run experience by running arbitrary cmd
RUN dotnet --info

# see: https://dotnet.microsoft.com/download/dotnet-core/6.0
RUN dotnet_sdk_version=6.0.100 \
&& wget -qO dotnet.tar.gz \
"https://dotnetcli.azureedge.net/dotnet/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz" \
&& dotnet_sha512='cb0d174a79d6294c302261b645dba6a479da8f7cf6c1fe15ae6998bc09c5e0baec810822f9e0104e84b0efd51fdc0333306cb2a0a6fcdbaf515a8ad8cf1af25b' \
&& echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
&& tar -C /usr/lib64/dotnet -oxzf dotnet.tar.gz \
&& rm dotnet.tar.gz
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
