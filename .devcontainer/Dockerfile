# .devcontainer/Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install locales-all
ENV LANG=ja_JP.UTF-8



# ---------- ① base tools + JDK 17 ----------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl xz-utils unzip zip git wget \
        bash ca-certificates clang cmake ninja-build pkg-config \
        libglu1-mesa libgtk-3-dev openjdk-17-jdk \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*

# ---------- ② Dart SDK (x64) ----------
ARG DART_VERSION=3.6.0
RUN curl -L "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip" \
        -o /tmp/dart.zip && \
    unzip -q /tmp/dart.zip -d /usr/lib && \
    rm /tmp/dart.zip
ENV PATH="/usr/lib/dart-sdk/bin:${PATH}"

# ---------- ③ FVM & Flutter ----------
ARG FLUTTER_VERSION=3.27.0
RUN dart pub global activate fvm && \
    /root/.pub-cache/bin/fvm install ${FLUTTER_VERSION} --verbose && \
    /root/.pub-cache/bin/fvm global  ${FLUTTER_VERSION}

ENV PATH="/root/fvm/default/bin:/root/.pub-cache/bin:${PATH}"
ENV PATH="/root/fvm/versions/${FLUTTER_VERSION}/bin:${PATH}"

# ---------- ④ Android cmdline-tools ----------
ARG ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
        -o /tmp/cmd.zip && \
    unzip -q /tmp/cmd.zip -d /tmp && \
    mv /tmp/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmd.zip
ENV PATH="${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" "platforms;android-34" "build-tools;34.0.0"

RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses
