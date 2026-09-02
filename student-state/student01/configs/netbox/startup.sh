#!/bin/bash
set -e

echo "[INFO] Ajetaan NetBox-tietokantamigraatiot (migrate)..."
/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py migrate --no-input

echo "[INFO] Luodaan / paivitetaan NetBox-pääkäyttäjä (superuser)..."
/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py shell -c "
import os
from django.contrib.auth import get_user_model

User = get_user_model()
username = os.environ.get('SUPERUSER_NAME', 'admin')
email = os.environ.get('SUPERUSER_EMAIL', 'admin@example.local')
password = os.environ.get('SUPERUSER_PASSWORD', '')

if username and password:
    u, created = User.objects.get_or_create(
        username=username,
        defaults={'email': email, 'is_superuser': True}
    )
    u.set_password(password)
    u.email = email
    u.is_superuser = True
    u.save()
    if created:
        print(f'[OK] Superuser \"{username}\" luotu onnistuneesti.')
    else:
        print(f'[OK] Superuser \"{username}\" paivitetty onnistuneesti.')
"

echo "[INFO] Kerataan staatilliset tiedostot (collectstatic)..."
/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input

echo "[INFO] Kaynnistetaan NetBox..."
exec /opt/netbox/launch-netbox.sh
