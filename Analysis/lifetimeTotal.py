import sys
import csv

if len(sys.argv) != 2:
    print "Please specify a file to read"
    sys.exit(1)

fileToPlot = open(sys.argv[1], "r")
csvReader = csv.DictReader(fileToPlot)

totalSum = 0
for row in csvReader:
    totalSum += int(row["data"])

print "Lifetime total: " + str(totalSum)
