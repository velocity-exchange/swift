FROM rust:1.91.1-bookworm AS builder

RUN apt update -y && \
  apt install -y git libssl-dev

ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add rustfmt

WORKDIR /app
# protocol-v2-shadow (the `drift` crate) and drift-rs are consumed as path-dep
# siblings of swift. The build context is the parent dir holding all three; CI
# checks them out side by side (see .github/workflows). Preserve the relative
# layout so Cargo's `../drift-rs` / `../protocol-v2-shadow` paths resolve.
COPY protocol-v2-shadow ./protocol-v2-shadow
COPY drift-rs ./drift-rs
COPY swift ./swift

WORKDIR /app/swift
RUN cargo build --release

FROM amazonlinux:2023

RUN yum install -y openssl

COPY --from=builder /app/swift/target/release/swift-server /usr/local/bin/swift-server

ENTRYPOINT ["/usr/local/bin/swift-server"]
