#!/var/ossec/framework/python/bin/python3
# ================================================================
# Wazuh → TheHive Integration Script
# ================================================================
#
# Script ini OTOMATIS dipanggil oleh Wazuh integratord setiap kali
# ada alert yang memenuhi filter (level >= 10).
#
# Apa yang dilakukan:
# 1. Baca alert JSON dari Wazuh
# 2. Parse informasi penting (rule, agent, source IP, dll)
# 3. Buat Alert di TheHive via API
#
# Lokasi di server: /var/ossec/integrations/custom-w2thive.py
# Permissions: chmod 755, chown root:wazuh
# ================================================================

import json
import sys
import os
import re
import logging
from datetime import datetime

# Setup logging
LOG_FILE = '/var/ossec/logs/integrations.log'
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s | TheHive-Integration | %(levelname)s | %(message)s'
)

# Severity mapping: Wazuh level → TheHive severity
# TheHive severity: 1=Low, 2=Medium, 3=High, 4=Critical
def get_severity(level):
    level = int(level)
    if level >= 14:
        return 4  # Critical
    elif level >= 10:
        return 3  # High
    elif level >= 7:
        return 2  # Medium
    else:
        return 1  # Low

# TLP mapping berdasarkan level
def get_tlp(level):
    level = int(level)
    if level >= 14:
        return 3  # TLP:RED
    elif level >= 10:
        return 2  # TLP:AMBER
    else:
        return 1  # TLP:GREEN

def create_thehive_alert(alert_data, thehive_url, thehive_api_key):
    """
    Buat alert di TheHive dari data alert Wazuh
    """
    try:
        from thehive4py.api import TheHiveApi
        from thehive4py.models import Alert, AlertArtifact
    except ImportError:
        logging.error("thehive4py belum terinstall! Jalankan: /var/ossec/framework/python/bin/pip3 install thehive4py==1.8.1")
        return

    try:
        api = TheHiveApi(thehive_url, thehive_api_key)

        # Extract data dari Wazuh alert
        rule = alert_data.get('rule', {})
        agent = alert_data.get('agent', {})
        data = alert_data.get('data', {})
        location = alert_data.get('location', '')
        full_log = alert_data.get('full_log', '')
        timestamp = alert_data.get('timestamp', datetime.now().isoformat())

        rule_id = rule.get('id', '0')
        rule_level = rule.get('level', '0')
        rule_description = rule.get('description', 'Wazuh Alert')
        rule_groups = rule.get('groups', [])
        agent_name = agent.get('name', 'unknown')
        agent_id = agent.get('id', '000')
        srcip = data.get('srcip', '')

        # Tentukan tipe alert berdasarkan rule groups
        alert_type = 'wazuh-alert'
        if 'ddos' in rule_groups or 'soar' in rule_groups:
            alert_type = 'soar-ddos'
        elif 'brute_force' in rule_groups:
            alert_type = 'brute-force'
        elif 'web' in rule_groups:
            alert_type = 'web-attack'
        elif 'syscheck' in rule_groups:
            alert_type = 'file-integrity'

        # Buat tags dari rule groups
        tags = ['wazuh', f'rule-{rule_id}', f'level-{rule_level}', f'agent-{agent_name}']
        for group in rule_groups:
            tags.append(group)

        # Buat description yang informatif
        description = f"""## Wazuh Alert Details

**Rule ID:** {rule_id}
**Rule Level:** {rule_level}
**Rule Description:** {rule_description}
**Groups:** {', '.join(rule_groups)}

---

### Agent Info
- **Agent Name:** {agent_name}
- **Agent ID:** {agent_id}

### Source Info
- **Source IP:** {srcip if srcip else 'N/A'}
- **Location:** {location}

### Full Log
```
{full_log}
```

### Raw Alert Data
```json
{json.dumps(alert_data, indent=2, default=str)}
```
"""

        # Buat artifacts (observables)
        artifacts = []
        if srcip:
            artifacts.append(AlertArtifact(
                dataType='ip',
                data=srcip,
                message=f'Source IP dari alert Wazuh Rule {rule_id}',
                tags=['wazuh', 'source-ip']
            ))

        # Buat unique sourceRef (agar tidak duplikat)
        alert_id = alert_data.get('id', '')
        source_ref = f"wazuh-{rule_id}-{alert_id}-{timestamp}"
        # Bersihkan karakter yang tidak valid
        source_ref = re.sub(r'[^a-zA-Z0-9\-_]', '_', source_ref)[:64]

        # Buat Alert object
        thehive_alert = Alert(
            title=f"[Wazuh] {rule_description}",
            tlp=get_tlp(rule_level),
            severity=get_severity(rule_level),
            tags=tags,
            description=description,
            type=alert_type,
            source='Wazuh-SIEM',
            sourceRef=source_ref,
            artifacts=artifacts
        )

        # Kirim ke TheHive
        response = api.create_alert(thehive_alert)

        if response.status_code == 201:
            logging.info(f"Alert berhasil dibuat di TheHive: Rule {rule_id} - {rule_description} (Agent: {agent_name})")
        else:
            logging.error(f"Gagal buat alert di TheHive: HTTP {response.status_code} - {response.text}")

    except Exception as e:
        logging.error(f"Error koneksi ke TheHive: {str(e)}")


def main():
    """
    Entry point — dipanggil oleh Wazuh integratord
    
    Arguments dari Wazuh:
    sys.argv[1] = path ke file alert (JSON)
    sys.argv[2] = API key
    sys.argv[3] = hook_url (TheHive URL)
    """
    if len(sys.argv) < 4:
        logging.error(f"Argumen tidak lengkap. Diterima: {len(sys.argv)} argumen. Butuh: 4 (script, alert_file, api_key, hook_url)")
        sys.exit(1)

    alert_file_path = sys.argv[1]
    api_key = sys.argv[2]
    hook_url = sys.argv[3]

    # Baca alert file
    try:
        with open(alert_file_path, 'r') as f:
            alert_json = json.load(f)
    except Exception as e:
        logging.error(f"Gagal baca file alert {alert_file_path}: {str(e)}")
        sys.exit(1)

    logging.info(f"Memproses alert: Rule {alert_json.get('rule', {}).get('id', '?')} - {alert_json.get('rule', {}).get('description', '?')}")

    # Kirim ke TheHive
    create_thehive_alert(alert_json, hook_url, api_key)


if __name__ == "__main__":
    main()
