import sys
import csv
import datetime

import numpy as np
import matplotlib.pyplot as plt

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

numBins = 48
binLengthInMinutes = (24 * 60) / numBins

binLowerBoundaries = []
for i in range(0, numBins + 1):
    binLowerBoundaries.append(i * binLengthInMinutes)

bins = [0 for i in range(0, len(binLowerBoundaries))]
for i in range(0, len(timestamps)):
    timestampOfData = timestamps[i]
    bindex = int(((timestampOfData.hour * 60) + timestampOfData.minute) / binLengthInMinutes)
    bins[bindex] += data[i]

xTickLabels = []
for lowerBoundary in binLowerBoundaries:
    hour = int(lowerBoundary / 60)
    minute = lowerBoundary % 60
    minuteZero = "0" if minute < 10 else ""
    xTickLabels.append(str(hour) + ":" + minuteZero + str(minute))

plt.bar(binLowerBoundaries, bins, width=binLengthInMinutes)
plt.xticks(binLowerBoundaries[0::4], xTickLabels[0::4], horizontalalignment="right", rotation=25)
plt.xlim(0, 1440)
plt.grid(True)
plt.suptitle(sys.argv[1])
plt.show()
