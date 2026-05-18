<<<<<<< HEAD
# Wazuh SIEM Project - Setup Guide

## Overview
Project monitoring keamanan jaringan menggunakan Wazuh SIEM dengan arsitektur 1 Manager + 3 Agent. Didesain khusus untuk di-deploy menggunakan **Microsoft Azure for Students** untuk keperluan tugas mahasiswa tanpa perlu mengeluarkan biaya.

## Struktur Folder
```
wazuh-project/
├── README.md                    # Panduan ini
├── docs/
│   ├── architecture.md          # Arsitektur & alur sistem
│   ├── setup-manager.md         # Setup Wazuh Manager (Azure)
│   ├── setup-agent.md           # Setup Wazuh Agent di laptop
│   ├── setup-malware.md         # Setup Malware Detection Module ⭐
│   └── attack-simulation.md     # Simulasi serangan
├── configs/
│   ├── manager/
│   │   └── ossec.conf           # Konfigurasi manager (+ VirusTotal integration)
│   └── agent/
│       └── ossec.conf           # Konfigurasi agent
├── scripts/
│   ├── install-manager.sh       # Script install manager
│   ├── install-agent.sh         # Script install agent
│   ├── attack-bruteforce.sh     # Simulasi brute force SSH
│   ├── attack-web.sh            # Simulasi web attack
│   ├── attack-fim.sh            # Simulasi File Integrity
│   ├── attack-rootkit.sh        # Simulasi rootkit detection
│   └── attack-malware.sh        # Simulasi malware detection ⭐
└── rules/
    └── custom-rules.xml         # Custom detection rules
```
=======
# MIKS-C-K4

#### Nama Anggota
| No. | Nama                                    | NRP         | 
|-----|-----------------------------------------|-------------|
| 1   | Revalina Erica Permatasari              | 5027241007  | 
| 2   | Syifa Nurul Alfiah                      | 5027241019  | 
| 3   | Salsa Bil Ulla                          | 5027241052  | 
| 4   | Putri Joselina Silitonga                | 5027241116  | 
>>>>>>> 47eebbd67c20aee33f8ce499c228839d58b6ddfb
