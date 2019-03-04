#!/usr/bin/env python

import json
import sys
from pprint import pprint

args = sys.argv
if len(args) != 2:
  print "Usage: parse_trace [file_name]"
  sys.exit(1)
trace_file = args[1]

# keys: (pid, tid, id, name)
# values: [timestamp]
parsed_data = {}
keys_of_interest = ["pid", "tid", "id", "name"]
types_of_interest = ["O", "N"]
value_of_interest = "ts"

# Parse log
with open(trace_file) as f:
  data = json.load(f)
  for event in data["traceEvents"]:
    # Parse type
    if event["ph"] not in types_of_interest:
      continue
    # Parse key
    key = []
    for k in keys_of_interest:
      if k in event:
        key.append(event[k])
    if len(key) != len(keys_of_interest):
      continue
    key = tuple(key)
    if key not in parsed_data:
      parsed_data[key] = []
    # Parse value
    if value_of_interest not in event:
      raise ValueError("Value '%s' not found in event:\n%s" % (value_of_interest, event))
    value = event[value_of_interest]
    parsed_data[key].append(value)

# Print duration of each op
print "Name: duration (us)"
max_duration_name = None
max_duration = 0
for k, v in parsed_data.items():
  name = k[keys_of_interest.index("name")]
  if len(v) != 2:
    raise ValueError("Event '%s' did not have exactly 2 timestamps: %s" % (name, v))
  duration = v[1] - v[0]
  if duration < 0:
    raise ValueError("Event '%s' did not have timestamps in the right order" % (name, v))
  if duration > max_duration:
    max_duration_name = name
    max_duration = duration
  print "%s: %s" % (name, duration)

# Print op with max duration
print "\nMax duration:"
print "%s: %s" % (max_duration_name, max_duration)

