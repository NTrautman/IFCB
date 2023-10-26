# IFCB
Quality control and data processing scripts for the California IFCB network.
Before running the scripts, download files from the [IFCB dashboard](https://ifcb.caloos.org/dashboard) if you do not already have them stored on your local machine.
## IFCB_QC_share
Semi-automated quality control for IFCB sample data.
Change the following variables in the USER INPUTS section before running the script:
- **IFCB_id:** should match your instrument, e.g., 163 for Bodega Marine Lab
- **sample_date:** date you want to QC (can only do one day at a time)
- **loc:** location of IFCB files in local directory
- **flag_loc:** location to write QC flag data to
- **metadata_loc:** location to write metadata.csv file to before copying it to
the IFCB computer
## IFCB_QC_share_WindowsOS
Version of IFCB_QC_share that will work on machines running Windows OS.

When you are done with QC, copy the metadata.csv file to the appropriate directory location on the IFCB computer so that it will get uploaded to the IFCB dashboard the next time rsync is run on the IFCB computer.
### USER INPUTS
Variables that specify which IFCB sample to QC and its directory location.
### LOCATE IFCB FILES
Calls a user-defined function, get_data_IFCB, to locate all of the sample files for the user-specified date.  Once the files have been located, the script begins to loop through them one sample at a time for the specified date.
### LOAD DATA
Extracts relevant QC parameters from .adc and .hdr files, prints a summary to the command window, and plots ROIy vs. ROIx for the sample.
### AUTOMATED QC CHECKS
Checks each sample to see if the sample volume, run time, images-to-triggers ratio, and humidity exceed certain thresholds and flags the sample if one or more do.
### WRITE FLAG STRUCT TO flag.csv FILE
Writes the flags to a .csv file associated with a particular IFCB instrument.  This file is continuosly updated as you run through the samples.
### WRITE SKIP FLAGS TO metadata.csv FILE
If a sample is flagged for failing one or more of the QC checks, it is assigned a skip flag, which is recorded to the metadata.csv file associated with a particular IFCB instrument.  This is the file that gets uploaded to the IFCB dashboard.
### PROMPT FOR NEXT SAMPLE
Asks the user if they want to continue on to the next sample if a skip flag was generated.
