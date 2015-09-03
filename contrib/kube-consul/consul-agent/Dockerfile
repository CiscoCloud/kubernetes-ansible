FROM ldejager/consul:latest
ADD ./config /opt/consul/config/
ADD https://dl.bintray.com/mitchellh/consul/0.5.2_web_ui.zip /tmp/webui.zip
RUN cd /tmp && unzip webui.zip && mv dist /opt/consul/ui && rm webui.zip
EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 8600 8600/udp 53 53/udp
ENV DNS_RESOLVES consul
ENV DNS_PORT 53
ENTRYPOINT ["/opt/consul/bin/consul", "agent", "-server", "-config-dir=/opt/consul/config"]
