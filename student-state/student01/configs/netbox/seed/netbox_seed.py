import os

from dcim.models import Cable, CableTermination, Device, DeviceRole, DeviceType, Interface, Manufacturer, Site
from django.db import transaction
from extras.models import Tag
from ipam.models import IPAddress, Prefix

try:
    from netbox_topology_views.models import Coordinate, CoordinateGroup
except Exception:
    Coordinate = None
    CoordinateGroup = None


RESET = os.getenv("NB_SEED_RESET", "0") == "1"
TAG_NAME = "clab-seed"
SITE_NAME = "HAMK Verkonhallinta Lab"
SITE_SLUG = "hamk-verkonhallinta-lab"


def ensure(model, lookup, defaults=None):
    defaults = defaults or {}
    obj, created = model.objects.get_or_create(**lookup, defaults=defaults)
    if not created and defaults:
        changed = False
        for key, value in defaults.items():
            if getattr(obj, key) != value:
                setattr(obj, key, value)
                changed = True
        if changed:
            obj.save()
    return obj


def tag_object(obj, tag):
    if not obj.tags.filter(id=tag.id).exists():
        obj.tags.add(tag)


def ensure_cable_between(left_iface, right_iface, tag):
    left_term = CableTermination.objects.filter(interface=left_iface).first()
    right_term = CableTermination.objects.filter(interface=right_iface).first()

    if left_term and right_term and left_term.cable_id == right_term.cable_id:
        return

    if left_term:
        left_term.cable.delete()
    if right_term:
        right_term.cable.delete()

    cable = Cable(status="connected")
    cable.save()
    CableTermination.objects.create(cable=cable, cable_end="A", termination=left_iface)
    CableTermination.objects.create(cable=cable, cable_end="B", termination=right_iface)
    tag_object(cable, tag)


def seed_topology_views(tag, devices):
    if CoordinateGroup is None or Coordinate is None:
        print("[WARN] Topology Views plugin ei saatavilla, skipataan valmiit nakymat")
        return

    view_layouts = {
        "Labra Full": {
            "r1": (100, 220),
            "r2": (320, 220),
            "r3": (540, 220),
            "client1": (80, 120),
            "attacker": (80, 320),
            "srv-bp": (340, 120),
            "web1": (460, 80),
            "db1": (460, 160),
            "mgmt-bp": (340, 320),
            "ansible": (460, 280),
            "prometheus": (460, 340),
            "grafana": (460, 400),
            "zabbix": (460, 460),
            "branch-client": (640, 220),
        },
        "Labra Core": {
            "r1": (120, 160),
            "r2": (320, 160),
            "r3": (520, 160),
            "srv-bp": (320, 60),
            "mgmt-bp": (320, 260),
        },
        "Labra Management": {
            "r2": (160, 180),
            "mgmt-bp": (320, 180),
            "ansible": (500, 100),
            "prometheus": (500, 160),
            "grafana": (500, 220),
            "zabbix": (500, 280),
        },
    }

    for view_name, coord_map in view_layouts.items():
        group = ensure(
            CoordinateGroup,
            {"name": view_name},
            {"description": "Automaattisesti luotu containerlab-topologian nakyma"},
        )
        tag_object(group, tag)

        for dev_name, (x, y) in coord_map.items():
            if dev_name not in devices:
                continue
            coord = ensure(
                Coordinate,
                {"group": group, "device": devices[dev_name]},
                {"x": x, "y": y},
            )
            if coord.x != x or coord.y != y:
                coord.x = x
                coord.y = y
                coord.save()
            tag_object(coord, tag)


@transaction.atomic
def run_seed():
    tag = ensure(Tag, {"name": TAG_NAME}, {"slug": TAG_NAME, "description": "Containerlab bootstrap seed"})

    site = ensure(
        Site,
        {"slug": SITE_SLUG},
        {
            "name": SITE_NAME,
            "status": "active",
            "description": "Kurssin containerlab-ymparisto",
        },
    )
    tag_object(site, tag)

    if RESET:
        print("[INFO] Reset mode paalla: poistetaan aiemmin seedatut laitteet ja prefixit")
        if CoordinateGroup is not None:
            CoordinateGroup.objects.filter(tags__slug=TAG_NAME).delete()
        Cable.objects.filter(tags__slug=TAG_NAME).delete()
        Device.objects.filter(tags__slug=TAG_NAME, site=site).delete()
        Prefix.objects.filter(tags__slug=TAG_NAME).delete()

    manufacturer = ensure(
        Manufacturer,
        {"slug": "containerlab"},
        {"name": "Containerlab"},
    )

    role_router = ensure(DeviceRole, {"slug": "router"}, {"name": "Router", "color": "ff9800"})
    role_server = ensure(DeviceRole, {"slug": "server"}, {"name": "Server", "color": "2196f3"})
    role_client = ensure(DeviceRole, {"slug": "client"}, {"name": "Client", "color": "4caf50"})
    role_security = ensure(DeviceRole, {"slug": "security"}, {"name": "Security", "color": "f44336"})
    role_mgmt = ensure(DeviceRole, {"slug": "management"}, {"name": "Management", "color": "9c27b0"})
    role_switch = ensure(DeviceRole, {"slug": "switch"}, {"name": "Switch", "color": "607d8b"})

    dt_router = ensure(
        DeviceType,
        {"slug": "frr-router", "manufacturer": manufacturer},
        {"model": "FRR Router", "u_height": 1},
    )
    dt_linux = ensure(
        DeviceType,
        {"slug": "linux-node", "manufacturer": manufacturer},
        {"model": "Linux Node", "u_height": 1},
    )

    prefixes = [
        ("10.10.10.0/24", "User LAN"),
        ("10.10.20.0/24", "Server LAN"),
        ("10.10.30.0/24", "Branch LAN"),
        ("10.10.99.0/24", "Management LAN"),
        ("10.255.12.0/30", "R1-R2 P2P"),
        ("10.255.23.0/30", "R2-R3 P2P"),
        ("172.20.20.0/24", "Containerlab mgmt"),
    ]

    for cidr, desc in prefixes:
        pfx = ensure(
            Prefix,
            {"prefix": cidr, "vrf": None},
            {"status": "active", "description": desc},
        )
        tag_object(pfx, tag)

    devices = {
        "r1": (role_router, dt_router),
        "r2": (role_router, dt_router),
        "r3": (role_router, dt_router),
        "client1": (role_client, dt_linux),
        "attacker": (role_security, dt_linux),
        "web1": (role_server, dt_linux),
        "db1": (role_server, dt_linux),
        "branch-client": (role_client, dt_linux),
        "srv-bp": (role_switch, dt_linux),
        "mgmt-bp": (role_switch, dt_linux),
        "ansible": (role_mgmt, dt_linux),
        "prometheus": (role_mgmt, dt_linux),
        "grafana": (role_mgmt, dt_linux),
        "zabbix": (role_mgmt, dt_linux),
    }

    interfaces = {
        "r1": ["eth1", "eth2", "eth3", "mgmt0"],
        "r2": ["eth1", "eth2", "eth3", "eth4", "mgmt0"],
        "r3": ["eth1", "eth2", "mgmt0"],
        "client1": ["eth1", "mgmt0"],
        "attacker": ["eth1", "mgmt0"],
        "web1": ["eth1", "mgmt0"],
        "db1": ["eth1", "mgmt0"],
        "branch-client": ["eth1", "mgmt0"],
        "srv-bp": ["eth1", "eth2", "eth3", "mgmt0"],
        "mgmt-bp": ["eth1", "eth2", "eth3", "eth4", "eth5", "mgmt0"],
        "ansible": ["eth1", "mgmt0"],
        "prometheus": ["eth1", "mgmt0"],
        "grafana": ["eth1", "mgmt0"],
        "zabbix": ["eth1", "mgmt0"],
    }

    ip_map = {
        ("r1", "eth1"): "10.255.12.1/30",
        ("r2", "eth1"): "10.255.12.2/30",
        ("r2", "eth4"): "10.255.23.1/30",
        ("r3", "eth1"): "10.255.23.2/30",
        ("r1", "eth2"): "10.10.10.1/24",
        ("r1", "eth3"): "10.10.10.254/24",
        ("client1", "eth1"): "10.10.10.101/24",
        ("attacker", "eth1"): "10.10.10.200/24",
        ("r2", "eth2"): "10.10.20.1/24",
        ("web1", "eth1"): "10.10.20.101/24",
        ("db1", "eth1"): "10.10.20.102/24",
        ("r2", "eth3"): "10.10.99.1/24",
        ("ansible", "eth1"): "10.10.99.10/24",
        ("prometheus", "eth1"): "10.10.99.20/24",
        ("grafana", "eth1"): "10.10.99.30/24",
        ("zabbix", "eth1"): "10.10.99.40/24",
        ("r3", "eth2"): "10.10.30.1/24",
        ("branch-client", "eth1"): "10.10.30.101/24",
    }

    cables = [
        (("r1", "eth1"), ("r2", "eth1")),
        (("r2", "eth4"), ("r3", "eth1")),
        (("r1", "eth2"), ("client1", "eth1")),
        (("r1", "eth3"), ("attacker", "eth1")),
        (("r2", "eth2"), ("srv-bp", "eth1")),
        (("web1", "eth1"), ("srv-bp", "eth2")),
        (("db1", "eth1"), ("srv-bp", "eth3")),
        (("r2", "eth3"), ("mgmt-bp", "eth1")),
        (("ansible", "eth1"), ("mgmt-bp", "eth2")),
        (("prometheus", "eth1"), ("mgmt-bp", "eth3")),
        (("grafana", "eth1"), ("mgmt-bp", "eth4")),
        (("zabbix", "eth1"), ("mgmt-bp", "eth5")),
        (("r3", "eth2"), ("branch-client", "eth1")),
    ]

    created_devices = {}

    for name, (role, devtype) in devices.items():
        dev = ensure(
            Device,
            {"name": name},
            {
                "site": site,
                "status": "active",
                "role": role,
                "device_type": devtype,
            },
        )
        if dev.site != site:
            dev.site = site
            dev.save()
        tag_object(dev, tag)
        created_devices[name] = dev

    for name, iface_names in interfaces.items():
        dev = created_devices[name]
        for iface_name in iface_names:
            iface_type = "virtual" if iface_name == "mgmt0" else "1000base-t"
            iface = ensure(
                Interface,
                {"device": dev, "name": iface_name},
                {"type": iface_type, "enabled": True},
            )
            if iface.type != iface_type:
                iface.type = iface_type
                iface.save()
            tag_object(iface, tag)

    for (dev_name, iface_name), address in ip_map.items():
        iface = Interface.objects.get(device=created_devices[dev_name], name=iface_name)
        ip = ensure(IPAddress, {"address": address, "vrf": None}, {"status": "active"})
        if ip.assigned_object_id != iface.id:
            ip.assigned_object = iface
            ip.save()
        tag_object(ip, tag)

    for (left_dev, left_if), (right_dev, right_if) in cables:
        left_iface = Interface.objects.get(device=created_devices[left_dev], name=left_if)
        right_iface = Interface.objects.get(device=created_devices[right_dev], name=right_if)
        ensure_cable_between(left_iface, right_iface, tag)

    seed_topology_views(tag, created_devices)

    print("[OK] NetBox seed valmis")
    print(f"[INFO] Mode: {'reset' if RESET else 'upsert'}")
    print("[INFO] Seedatut laitteet:", ", ".join(sorted(devices.keys())))


run_seed()