#!/bin/ksh93
####################################################################################################
# Script:                  xxrdffilemove.ksh
# Author:                  Debakanta Panda
# Date  :                  21-JUN-2017
# Description:             This script is to search for all rdf files in a path and move them
#                          parellely to another path.
# syntax for usage:        xxrdffilemove.sh -d $d
# Version   :                      1.3
# Revision          Date         Name                Change Description
# --------      -----------   ------------       ----------------------------------------------------------
#  1.1           01/03/2021       Kishor                       Additional validation, files actually moved to archive/not
#  1.2           05/06/2022   George Fatsis      Changed the path to search for the PRESENT_FILES and
#                                                PRESENT_NAMES needed under $RS_V_CONTROL. Also,
#                                                updated the shell to ksh93 and the suffix of the
#                                                script to ksh.
#  1.3           06-Jun-2022  Ioannis K          Added block to remove present file/name lists
#  1.4           15-Sep-2023  Shubh Dedhia       Moving all the batch inbound and outbound files to respective inbound and outbound directories within _archive path.
#                                                Modified the logic for additional check validation
#                             Geetika Bhawra     Creating four directories such as from_sis,from_rms2,from_irc,from_rpas.

###################################################################
# Initialize script
#
cd ${0%/*}
. $RS_V_SCRIPTS/custom.ksh "$@"
StartLog "$0"
AssertInMaster


LogInfo "Initializing Parameters"
PROG_NAME=`basename $0`
DATESTR=`date +"%Y%m%d"`
#LOGPATH=/rdf/util
FILEPATH=/xfer/rdf
DESTINATION=_archive
#LOG_FILE=${LOGPATH}/logs/${PROG_NAME}_${DATESTR}.log
#PRESENT_FILES=${LOGPATH}/present_rdf_files.dat
#PRESENT_NAMES=${LOGPATH}/present_rdf_file_names.dat
#ERROR_LOG=${LOGPATH}/error/${PROG_NAME}.err
LOG_FILE=$UTIL_LOGS/${PROG_NAME}_${DATESTR}.log
PRESENT_FILES=$RS_V_CONTROL/present_rdf_files.dat
PRESENT_NAMES=$RS_V_CONTROL/present_rdf_file_names.dat
RDFRMS2_inbound_ctl_file=$RS_V_CONTROL/RMS2_Inbound_file.dat
RDFSIS_inbound_ctl_file=$RS_V_CONTROL/SIS_Inbound_file.dat
RDFIRC_inbound_ctl_file=$RS_V_CONTROL/IRC_Inbound_file.dat
RDF_outbound_ctl_file=$RS_V_CONTROL/Outbound_file.dat
ERROR_LOG=$UTIL_ERR/${PROG_NAME}.err
MAX_PARALLEL=10
export ENV=`echo $RPAS_ENV`
export Schedule_Date=`cat /app/control/rdf/RDF_BATCH_RUNDATE`


rm -f ${ERROR_LOG}

#if [ $# -ne 2 ];then
#   LogError "Please pass correct no of arguments that is 2" ${ERROR_LOG}
#        exit 1
#fi
#added to run directly via main script via tws
cd $UTIL_SCRIPTS
LogInfo `date +%a" "%b" "%e" "%T`" Program: ${PROG_NAME} : Started by ${USER}" ${LOG_FILE}

if [ -f ${RDFRMS2_inbound_ctl_file} ]; then
	rm -f ${RDFRMS2_inbound_ctl_file}
fi
if [ -f ${RDFSIS_inbound_ctl_file} ]; then
	rm -f ${RDFSIS_inbound_ctl_file}
fi
if [ -f ${RDFIRC_inbound_ctl_file} ]; then
	rm -f ${RDFIRC_inbound_ctl_file}
fi
if [ -f ${RDF_outbound_ctl_file} ]; then
	rm -f ${RDF_outbound_ctl_file}
fi

file=`cat $PRESENT_FILES`
for ArchivalFiles in $file 
do
RDFArchFile=`echo $ArchivalFiles`
RDFUpstreamSystem=`echo $RDFArchFile|awk -F '/' '{print $5}'`
#echo $RDFUpstreamSystem
#if [ ${UpstreamSystem} == "from_rms2" || ${UpstreamSystem} == "from_irc" || ${UpstreamSystem} == "from_sis" ]
#if [ "X${UpstreamSystem}" = "Xfrom_rms2" || "X${UpstreamSystem}" = "Xfrom_irc" || "X${UpstreamSystem}" = "Xfrom_sis" ]  
if [ ${RDFUpstreamSystem} == "from_rms2" ] 
then
echo $ArchivalFiles >> $RDFRMS2_inbound_ctl_file  
elif [ ${RDFUpstreamSystem} == "from_sis" ]
then
echo $ArchivalFiles >> $RDFSIS_inbound_ctl_file
elif [ ${RDFUpstreamSystem} == "from_irc" ]
then
echo $ArchivalFiles >> $RDFIRC_inbound_ctl_file
elif [ ${RDFUpstreamSystem} == "from_rpas" ]
then
echo $ArchivalFiles >> $RDF_outbound_ctl_file
else
continue
fi
done
RDFInbound=${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound
RDFOutbound=${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound
if [ ! -d $"RDFInbound" ]; then
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_rms2
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_irc
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_sis
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_aip
fi
if [ ! -d $"RDFOutbound" ]; then
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound
mkdir -p ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound/from_rpas
fi

cd ${FILEPATH}/$ENV/from_rms2
RDFRMS2File=`cat $RDFRMS2_inbound_ctl_file`
for RDFFilemover in $RDFRMS2File
do
RDFFilemoverRMS2=`echo $RDFFilemover|awk -F '/' '{print $6}'`
mv $RDFFilemoverRMS2 ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_rms2/
done
cd ${FILEPATH}/$ENV/from_sis
RDFSISFILE=`cat $RDFSIS_inbound_ctl_file`
for RDFFilemover in $RDFSISFILE
do
RDFFilemoverSIS=`echo $RDFFilemover|awk -F '/' '{print $6}'`
mv $RDFFilemoverSIS ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_sis/
done
cd ${FILEPATH}/$ENV/from_irc
RDFIRCFILE=`cat $RDFIRC_inbound_ctl_file`
for RDFFilemover in $RDFIRCFILE
do
RDFFilemoverIRC=`echo $RDFFilemover|awk -F '/' '{print $6}'`
mv $RDFFilemoverIRC ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_irc/
done
cd ${FILEPATH}/$ENV/from_rpas
RDFRPASFile=`cat $RDF_outbound_ctl_file`
for RDFFilemover in $RDFRPASFile
do
RDFFilemoverRPAS=`echo $RDFFilemover|awk -F '/' '{print $6}'`
mv $RDFFilemoverRPAS ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound/from_rpas/
done

#Added for moving aip mapping file
mv ${FILEPATH}/$ENV/from_aip/aip_scls_mapping.txt* ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_aip/
if [ $? -ne 0 ]; then
     LogError "File Movement Failed: ${FILEPATH}/$ENV/from_aip/aip_scls_mapping.txt" ${ERROR_LOG}
else
     LogInfo "File Exist: ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/from_aip/aip_scls_mapping.txt PASSED." ${LOG_FILE}
fi

#########SCSART-33820 Additional Check: Files moved to archive/not
file1=`cat ${PRESENT_FILES}`
for i in $file1
do
filename=`echo $i|awk -F '/' '{print $6}'`
filetype=`echo $i|awk -F '/' '{print $5}'`
rpasfilename=`echo $i|awk -F '/' '{print $7}'`
count=`find ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date -name ${filename} 2>/dev/null | wc -l`
if [ ${filetype} == "from_rpas" ] 
then
	if [ $count -lt 1 ]
	then
	LogError "File Not Exist: ${filename} to ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound/${filetype} FAILED." ${ERROR_LOG}
	else
	LogInfo "File Exist: ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/outbound/${filetype}/${filename}* PASSED." ${LOG_FILE}
	fi
elif [ ${filetype} == "rpas" ] 
then
cd ${FILEPATH}/$ENV/${filetype}/${filename}
rm rpasfilename
else
	if [ $count -lt 1 ]
	then
	LogError "File Not Exist: ${filename} to ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/${filetype} FAILED." ${ERROR_LOG}
	else
	LogInfo "File Exist: ${FILEPATH}/$ENV/${DESTINATION}/$Schedule_Date/inbound/${filetype}/${filename}* PASSED." ${LOG_FILE}
	fi
fi
done

#########SCSART-33820 Additinal Check: Files moved to archive/not
if [ -f ${ERROR_LOG} ];
   then
    LogInfo "moving of all files is unsuccesful . Please check ${ERROR_LOG} for more details" ${LOG_FILE}
 
        exit 1
else
       LogInfo "Moving of all files is succesful" ${LOG_FILE}
  
fi

#Removing present file lists - this was previously in RDF_FileCopy.ksh script
LogInfo "$(date +%Y%b%d' '%H:%M:%S) -- Removing files ${PRESENT_FILES} and ${PRESENT_NAMES}" >> $LOG_FILE
rm -f ${PRESENT_FILES}
rm -f ${PRESENT_NAMES}
if [[ $? -ne 0 ]]; then
   LogError "Error deleting the filename files. Exiting the process with error." >> ${ERROR_LOG}
   exit 1
fi
LogInfo `date +%a" "%b" "%e" "%T`" Program: ${PROG_NAME} : Completed by ${USER}" ${LOG_FILE}
exit 0

# Check log for errors and return calculated exit value
CloseLog
Cleanup


