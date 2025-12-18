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
^Snapshot\ Slices:\s*(?P<snapshot_slices>.*)$
[\s\S]*?
^Snapshot\ interval\ is\s*(?P<snapshot_interval>.*)$
[\s\S]*?
^Number\ of\ receivers\ is\s*(?P<receivers>.*)$
[\s\S]*?
^In-situ\ enabled:\s*(?P<in_situ_enabled>.*)$
[\s\S]*?
^Ex=(?P<Ex>\d+)\ Ey=(?P<Ey>\d+)\ Ez=(?P<Ez>\d+)$
[\s\S]*?
^Elapsed\ Initial\ Time\ :\ (?P<InitialTime>[\d\.]+)\ seconds.$
[\s\S]*?
^Elapsed\ Compute\ Time\ :\ (?P<ComputeTime>[\d\.]+)\ seconds.$
[\s\S]*?
^Elapsed\ TotalExe\ Time\ :\ (?P<TotalTime>[\d\.]+)\ seconds.$
"""

header = "Nodes,Elements,Timestep, In-situ, Simulated Time,Snapshot Enabled,Snapshot Interval,Snapshot Slices,Receivers,Ex,Ey,Ez,Initial Time,Compute Time,Total Time\n"
parsed_data = []

if len(sys.argv) != 2:
     exit(1)

dir_path = sys.argv[1]

for filename in os.listdir(dir_path):
        full_path = os.path.join(dir_path, filename)

        if os.path.isfile(full_path) and (not full_path.endswith(".snapshot")) and (not full_path.endswith(".sismos")):
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
                                extracted_data['in_situ_enabled'],
                                extracted_data['sim_time'],
                                extracted_data['snapshot_enabled'],
                                extracted_data['snapshot_interval'],
                                extracted_data['snapshot_slices'],
                                extracted_data['receivers'],
                                extracted_data['Ex'],
                                extracted_data['Ey'],
                                extracted_data['Ez'],
                                extracted_data['InitialTime'],
                                extracted_data['ComputeTime'],
                                extracted_data['TotalTime']])
                else:
                    print("Pattern not found")

            except FileNotFoundError:
                print("Error: File not found")


try:
    full_path = os.path.join(dir_path, "output")
    with open(full_path, "w") as f:  
        f.write(header)
        for row in parsed_data:
            f.write(",".join(row) + "\n")
        f.close()
        
except Exception as _:
        print("Failed to save output")
        exit(1)