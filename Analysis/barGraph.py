import sys
import csv
import datetime

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

if len(sys.argv) != 2:
    print "Please specify a file to read"
    sys.exit(1)

fileToPlot = open(sys.argv[1], "r")
csvReader = csv.DictReader(fileToPlot)

timestamps = []
data = []
for row in csvReader:
    timestamps.append(datetime.datetime.strptime(row["timestamp"], "%Y-%m-%d %H:%M:%S"))
    data.append(int(row["data"]))

fig, ax = plt.subplots()

ax.bar(timestamps, data, width=0.02)
ax.xaxis.set_major_locator(mdates.DayLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter("%m-%d"))
ax.grid(True)

fig.suptitle(sys.argv[1])
fig.autofmt_xdate()
plt.show()
