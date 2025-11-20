import re
import os
import sys

patterns = r"""
(?:[\s\S]*?)^Number\ of\ node\ is\ (?P<nodes>\d+)$
[\s\S]*?
^Number\ of\ element\ is\ (?P<elements>\d+)$
[\s\S]*?
^Time\ step\ is\ (?P<timestep>[\d\.]+)s$
[\s\S]*?
^Simulated\ time\ is\ (?P<sim_time>[\d\.]+)s$
[\s\S]*?
^Snapshot\ enabled:\s*(?P<snapshot_enabled>.*)$
[\s\S]*?
^Snapshot\ interval\ is\s*(?P<snapshot_interval>.*)$
[\s\S]*?
^Number\ of\ receivers\ is\s*(?P<receivers>.*)$
[\s\S]*?
^Ex=(?P<Ex>\d+)\ Ey=(?P<Ey>\d+)\ Ez=(?P<Ez>\d+)$
"""

header = "Nodes,Elements,Timestep,Simulated Time,Snapshot Enabled,Snapshot Interval,Receivers,Ex,Ey,Ez\n"
parsed_data = []

if len(sys.argv) != 2:
     exit(1)

dir_path = sys.argv[1]

for filename in os.listdir(dir_path):
        full_path = os.path.join(dir_path, filename)

        if os.path.isfile(full_path):
            try:
                with open(full_path, 'r') as f:
                    data = f.read()

                regex = re.compile(patterns, re.MULTILINE | re.VERBOSE)
                match = regex.search(data)

                if match:
                    extracted_data = match.groupdict()
                    parsed_data.append([extracted_data['nodes'], 
                                extracted_data['elements'],
                                extracted_data['timestep'],
                                extracted_data['sim_time'],
                                extracted_data['snapshot_enabled'],
                                extracted_data['snapshot_interval'],
                                extracted_data['receivers'],
                                extracted_data['Ex'],
                                extracted_data['Ey'],
                                extracted_data['Ez']])
                else:
                    print("Pattern not found")

            except FileNotFoundError:
                print("Error: File not found")
