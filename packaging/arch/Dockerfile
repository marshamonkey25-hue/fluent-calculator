FROM archlinux:base-devel
RUN pacman -Syu --noconfirm --needed cmake qt6-base qt6-declarative python dbus git ttf-dejavu \
    && pacman -Scc --noconfirm \
    && useradd --uid 1000 --create-home builder
COPY container-build.sh /usr/local/bin/calculator-arch-build
WORKDIR /build
