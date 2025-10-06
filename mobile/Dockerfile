FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  openjdk-17-jdk \
  wget \
  && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
  cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
  wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
  unzip commandlinetools-linux-9477386_latest.zip && \
  rm commandlinetools-linux-9477386_latest.zip && \
  mv cmdline-tools latest

RUN yes | sdkmanager --licenses && \
  sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin

RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} && \
  flutter doctor && \
  flutter config --no-analytics

WORKDIR /app

COPY . .

RUN flutter pub get && \
  flutter build apk --release

FROM alpine:3.22
WORKDIR /app
COPY --from=builder /app/build/app/outputs/flutter-apk/app-release.apk /app/client.apk
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
VOLUME /apkshare

CMD ["docker-entrypoint.sh"]
