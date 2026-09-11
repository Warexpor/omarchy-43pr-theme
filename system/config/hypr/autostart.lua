-- Extra autostart processes.
-- o.launch_on_start("my-service")
-- Proxy core (xray on 10808) - starts v2rayN GUI on login so proxy is up after reboot.
o.launch_on_start("/opt/v2rayn-bin/v2rayN")
