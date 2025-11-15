FROM ubuntu:20.04


WORKDIR /workdir

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /script
COPY --from=script  install-dep.sh /script/install-dep.sh
COPY --from=script  update-llvm.sh /script/update-llvm.sh
COPY --from=script  update-python.sh /script/update-python.sh
COPY --from=script  requirements.txt /script/requirements.txt

# run the main install script
RUN chmod +x /script/install-dep.sh
RUN /script/install-dep.sh

# delete path after installation, script will be attached to container from host
RUN rm -rf /script
