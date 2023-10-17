# IFCB
Quality control and data processing scripts for the California IFCB network.
Before running the scripts, download files from the IFCB dashboard if you do not already have them stored on your local machine:
https://ifcb.caloos.org/dashboard
## IFCB_QC_share
Semi-automated quality control for IFCB sample data.
Change the following variables before running the script:
IFCB_id: should match your instrument, e.g., 163 for Bodega Marine Lab
sample_date: date you want to QC (can only do one day at a time)
loc: location of IFCB files in local directory
flag_loc: location to write QC flag data to
metadata_loc: location to write metadata.csv file to before copying it to
the IFCB computer
When you are done with QC, copy the metadata.csv file to the appropriate directory location on the IFCB computer so that it will get uploaded to the IFCB dashboard the next time rsync is run on the IFCB computer.
