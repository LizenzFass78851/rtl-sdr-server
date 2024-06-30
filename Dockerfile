FROM debian:bookworm-slim as builder

# Install packages
RUN apt-get update -qq && apt-get upgrade -yy && \
  apt-get install -y libusb-1.0-0-dev \
    git cmake pkg-config && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Get driver repository
RUN git clone https://github.com/osmocom/rtl-sdr /workspace

# Compile drivers
RUN cd /workspace && \
        mkdir build && \
        cd build && \
        cmake ../ -DINSTALL_UDEV_RULES=ON && \
        make

FROM debian:bookworm-slim

# Install packages
RUN apt-get update -qq && apt-get upgrade -yy && \
  apt-get install -y libusb-1.0-0-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built files from builder
COPY --from=builder /workspace/build/src/rtl_tcp /usr/local/bin/
COPY --from=builder /workspace/build/src/*.so /usr/local/lib/

# Ensure rtl_tcp is executable and Install the drivers
RUN chmod +x /usr/local/bin/rtl_tcp && \
  ldconfig

# Execute RTL server
ENTRYPOINT ["rtl_tcp", "-a", "0.0.0.0"]
