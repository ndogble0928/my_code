---
- name: Stop and disable agent service
  ansible.builtin.service:
    name: swiagentd
    state: stopped
    enabled: false
  become: true
  failed_when: false  # service may already be gone

- name: Remove agent package
  ansible.builtin.package:
    name: swiagent
    state: absent
  become: true

- name: Remove leftover agent files
  ansible.builtin.file:
    path: "{{ item }}"
    state: absent
  loop:
    - /opt/SolarWinds/Agent
    - /tmp/inst
    - /tmp/swiagent.tar.gz
  become: true

-----
---
- name: Find SolarWinds Agent product code
  ansible.windows.win_shell: |
    $paths = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
             'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    Get-ItemProperty $paths -ErrorAction SilentlyContinue |
      Where-Object { $_.DisplayName -like 'SolarWinds Agent*' } |
      Select-Object -ExpandProperty PSChildName
  register: swi_product
  changed_when: false

- name: Uninstall SolarWinds Agent
  ansible.windows.win_package:
    product_id: "{{ item }}"
    state: absent
  loop: "{{ swi_product.stdout_lines }}"

- name: Remove leftover scheduled task
  community.windows.win_scheduled_task:
    name: SolarWindsAgentInstallOnce
    state: absent

- name: Remove leftover agent files
  ansible.windows.win_file:
    path: "{{ item }}"
    state: absent
  loop:
    - C:\Program Files (x86)\SolarWinds\Agent
    - C:\ProgramData\SolarWinds\Agent
    - C:\Temp\SolarWinds-Agent

----
- name: Run setup.bat
  ansible.windows.win_command: setup.bat
  args:
    chdir: C:\Temp\SolarWinds-Agent
    creates: C:\Program Files (x86)\SolarWinds\Agent
  register: setup_result
  failed_when: >-
    setup_result.rc | default(0) not in [0, 1] or
    'has successfully been created' not in setup_result.stdout | default('')
  changed_when: "'has successfully been created' in setup_result.stdout | default('')"

- name: Reboot to trigger silent install
  ansible.windows.win_reboot:
    reboot_timeout: 600
  when: setup_result is changed


----
- name: Download and extract agent
  ansible.builtin.unarchive:
    src: 
    dest: /tmp/inst
    remote_src: true
    creates: /tmp/inst/install.sh


-----
- name: Download agent bundle
  ansible.windows.win_get_url:
    url: "{{ swi_base_url }}/SolarWinds-Agent.zip"
    dest: C:\Temp\SolarWinds-Agent.zip
    checksum: "{{ swi_zip_sha256 }}"
    checksum_algorithm: sha256

- name: Extract bundle
  community.windows.win_unzip:
    src: C:\Temp\SolarWinds-Agent.zip
    dest: C:\Temp\SolarWinds-Agent
    creates: C:\Temp\SolarWinds-Agent\setup.bat
    delete_archive: true
