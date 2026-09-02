ARG NETBOX_VERSION=latest
FROM netboxcommunity/netbox:${NETBOX_VERSION}

COPY plugins/requirements.txt /opt/netbox/plugins/requirements.txt
RUN uv pip install --python /opt/netbox/venv/bin/python -r /opt/netbox/plugins/requirements.txt

COPY startup.sh /opt/netbox/startup.sh
RUN chmod +x /opt/netbox/startup.sh

