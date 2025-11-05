FROM scratch
COPY rootfs/bin/  /bin/
COPY rootfs/sbin/ /sbin/
COPY rootfs/usr/  /usr/
COPY rootfs/lib/  /lib/
COPY rootfs/etc/  /etc/
RUN mkdir -p /var/run/
RUN mkdir -p /var/lock/
RUN mkdir -p /tmp
ENV PATH=/bin:/sbin:/usr/bin:/usr/sbin
ENV LD_LIBRARY_PATH=/lib:/usr/lib
WORKDIR /
CMD ["/bin/busybox","sleep","infinity"]
