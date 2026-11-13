# syntax=docker/dockerfile:1.6
FROM alpine/git AS bindings
RUN git clone --depth=1 https://github.com/MutantBloodcell/bindings

FROM ghcr.io/geode-sdk/tools:android-latest AS build-android32

ARG GEODE_COMMIT_HASH=""

WORKDIR /workspace
COPY . .

RUN curl -Lf https://raw.githubusercontent.com/geode-sdk/geode-docker/refs/heads/main/docker/CMakePresets.json -o CMakePresets.json

RUN --mount=type=cache,target=/cpm-cache,id=cpm-android32 \
    --mount=type=cache,target=/opt/sccache/cache,id=sccache-android32 \
    --mount=type=bind,from=bindings,target=/bindings \
    cmake --preset android32-cache -DGEODE_DISABLE_PRECOMPILED_HEADERS=On -DGEODE_COMMIT_HASH=${GEODE_COMMIT_HASH} \
    && cmake --build --preset android32-cache && \
    ls /workspace/bin/nightly && sccache --show-stats

FROM scratch AS export-android32
COPY --from=build-android32 /workspace/bin/nightly/ .


FROM ghcr.io/geode-sdk/tools:android-latest AS build-android64

ARG GEODE_COMMIT_HASH=""

WORKDIR /workspace
COPY . .

RUN curl -Lf https://raw.githubusercontent.com/geode-sdk/geode-docker/refs/heads/main/docker/CMakePresets.json -o CMakePresets.json

RUN --mount=type=cache,target=/cpm-cache,id=cpm-android64 \
    --mount=type=cache,target=/opt/sccache/cache,id=sccache-android64 \
    --mount=type=bind,from=bindings,target=/bindings \
    cmake --preset android64-cache -DGEODE_DISABLE_PRECOMPILED_HEADERS=On -DGEODE_COMMIT_HASH=${GEODE_COMMIT_HASH} \
    && cmake --build --preset android64-cache && \
    ls /workspace/bin/nightly && sccache --show-stats

FROM scratch AS export-android64
COPY --from=build-android64 /workspace/bin/nightly/ .


FROM ghcr.io/geode-sdk/tools:ios-latest AS build-ios

ARG GEODE_COMMIT_HASH=""

WORKDIR /workspace
COPY . .

FROM debian:bookworm-slim AS export-combine

WORKDIR /workspace/export
COPY --from=export-android32 /Geode.android32.so .
COPY --from=export-android64 /Geode.android64.so .
COPY --from=export-win /resources .
