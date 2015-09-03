FROM alpine:3.2
ENV PATH /opt/kube2consul/bin:$PATH
RUN mkdir -vp /opt/kube2consul/bin
ADD ./kube2consul /opt/kube2consul/bin/
ENTRYPOINT ["/opt/kube2consul/bin/kube2consul", "-consul-agent=http://127.0.0.1:8500", "-kube_master_url=http://127.0.0.1:8080"] 
