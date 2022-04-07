#StorportPACMAN ported to Windows Powershell
#Paul Reynolds PaulRey@microsoft.com -> Improvements: Robin Hermann (RHE)
#version 1.1 updated for 2012 R2
#version 1.2 updated with performance enhancments
#version 1.3 updated to make filter for storport data more robust
#version 1.4 updated to make filter for storport data able to use storport ets trace data (insightweb)
#version 1.5 updated to include addition strings to flag storport data
#version 1.6 updated to fix bug in parameter errors
#version 1.7 updated to fix Excel 2016 ACE provider bug that converts hex to decimal on the fly
#version 1.8 updated to allow flexibility in installation directory 
#version 1.9 updated to clean up leading and trailing spaces in header information and data, which caused problems in an Office 2016 update regression issue
#version 2.0 updated to show warnings if data has any records with SCSI Status not 0 and/or SRB Status not 1
#version 3.0 RHE: updated to a function for more agility
#version 3.1 RHE: add more parameters and fix the with $MyInvocation, $MyInvocation is an automatic variable populated at script run time, then if you execute $MyInvocation.MyCommand.Path in a powershell console or ISE isn't populated
 
#You must run the script not the script content only!
 
Function Convert-ETWTraceToReadableFileCSV {
    [CmdletBinding()]
 
    #read in parameters for requestdurationvalue and ETL location
    Param(
        [Parameter(Position=0,mandatory=$false,HelpMessage="Path to the Skript and the Excel PowerPivot Templates (storport2012.xlsx)")][string]$WorkFolderPath = "C:\StorPortPACMAN",
        [Parameter(Position=1,mandatory=$false)][string]$Filter,
        [Parameter(Position=2,mandatory=$false)][string]$ETL,
        [Parameter(Position=3,mandatory=$false,HelpMessage="If you already converted the ETL to CSV")][string]$RAWXPerfCSVPath = $WorkFolderPath + '\raw-xperf.csv'
    )
 
    process {
        #edit this string for future change to storport data headers 
        $strStorportData = @('Microsoft-Windows-StorPort/Miniport','Microsoft-Windows-StorPort/Port /Info','Microsoft-Windows-StorPort/Port/win:Info','Microsoft-Windows-StorPort/TaskMiniportIORequestServiceTime');
 
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
 
        $storportpacmandirectory = $WorkFolderPath #Split-Path -Parent $MyInvocation.MyCommand.Path #"C:\StorPortPACMAN" 
        $requestduration_multiplier = 1 #this will change to 10,000 if the OS is Server 2012 due to differences in requestduration units (milliseconds in 2008, 100ns in 2012)
 
        #test if requestdurationvalue is present and a valid integer
        If ($filter -eq ''){
            $requestdurationvalue = 1000000 #default to 1000000 if not present(do NOT use commas)
        } else {
            If(($filter -as [Int64]) -eq $null) {
                [System.Windows.Forms.MessageBox]::Show('The request duration filter is either not a valid integer or has commas.')
                exit
            } else {
                $requestdurationvalue = [Int64]$filter
            }
        }
 
        If ($RAWPerfCSVPath -eq '') {
            #test if etl file is present and a valid file
            If($etl -eq '') {
                $ETLlocation = $storportpacmandirectory + '\storport.etl'
                If (-not (Test-Path $ETLlocation -PathType leaf)) {
                    [System.Windows.Forms.MessageBox]::Show('Sorry, but the file "Storport.etl" was not found.  Is it named correctly and in the storportpacman directory?')
                    exit
                }
            } else {
                If (-not (Test-Path $etl -PathType leaf)) {
                  [System.Windows.Forms.MessageBox]::Show('Sorry, but the file "' + $etl + '" was not found.')
                  exit
                } else {
                  $ETLlocation = $etl
                }
            }
 
            Write-Progress -Activity "StorportPACMAN Progress" -Status "Converting ETL file to CSV file via XPERF" -PercentComplete "33"
 
            try {
                $myargs = "-i " + ('"{0}"' -f $ETLlocation) + " -o "  + ('"{0}"' -f $storportpacmandirectory) + "\raw-xperf.csv -tle"
                Start-Process xperf -ArgumentList $myargs -Wait
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show('There was an error running XPerf.  Is it installed and in your system path?  The error message is ' + $_.Exception.Message)
                exit
            }
        }
 
 
        try {
            $reader = New-Object System.IO.StreamReader($RAWXPerfCSVPath)
            $writer = New-Object System.IO.StreamWriter($storportpacmandirectory + '\processed-xperf.csv')
        } catch {
            [System.Windows.Forms.MessageBox]::Show('There was an error creating the readers or writers.  Do you have write access to the ' + $storportpacmandirectory?  + ' The error message is ' + $_.Exception.Message)
            exit
        }
 
 
        try {
            Write-Progress -Activity "StorportPACMAN Progress" -Status "Scrubbing Data" -PercentComplete "50"
 
            $already_wrote_header = 'false';
            $request_duration_index = 14;
            $record_counter = 0;
            $scsi_status_not_0_counter=0;
            $srb_status_not_1_counter=0;
            $scsi_status_index = 16;
            $srb_status_index = 17;
 
            While ($reader.Peek() -gt -1) {
                $original_record = $reader.ReadLine()
 
                if ($original_record.Contains('OS Version:')) {
                    #check if O/S is windows 2012 or greater and if it is, make requestduration multiplier 10000 since requestdurations changed from millisecond to 100 nanosecond increments
                    #also request_duration column changes from 14 to 9
 
                    if ([Double]$original_record.Substring(11,4) -ge 6.2) {
                        $requestduration_multiplier = 10000;
                        $request_duration_index = 9;
                        $srb_status_index = 12;
                        $scsi_status_index = 18;
                    }
 
                    #get the trace start date time
                    $str_start_time = $original_record.Substring($original_record.IndexOf('Trace Start:') + ('trace start:').Length, $original_record.IndexOf(',', $original_record.IndexOf('Trace Start:')) - ($original_record.IndexOf('Trace Start:') + ('trace start:').Length));
                    $int_start_time = [Int64]($str_start_time);
                    $start_time = Get-Date('1/1/1601 12:00AM GMT');
                    $start_time = $start_time.AddTicks($int_start_time);
                    continue
                }
 
 
                #read in raw data and scrub it
                $isStorportData = 'false';
 
                foreach ($s in $strStorportData) {
                    if ($original_record.Contains($s)) {
                        $isStorportData = 'true';
                        break;
                    }
                }
 
                if ($isStorportData -eq 'true') { #this ignores all data except for lines with a string match in $strStorportData
                    $storport_data = $original_record.Split(',');
 
                    If(($storport_data[1] -as [Int64]) -ne $null) { #test for header versus data 
                        $record_counter = $record_counter + 1;
                        $dbl_delta_time = $storport_data[1] / 1000;
                        $storport_data[1] = $start_time.AddMilliseconds($dbl_delta_time).ToLocalTime().ToString();
 
                        #fix for Excel 2016 bug that converts hex to decimal on the fly
                        if($request_duration_index -eq 9) {
                            $storport_data[11] = '"' + $storport_data[11] + '"';
                            $storport_data[12] = '"' + $storport_data[12] + '"';
                            $storport_data[18] = '"' + $storport_data[18] + '"';
                        }
                        $header_flag = 'false'
                    } else {
                        $header_flag = 'true'
                    }
 
                    $original_record = $storport_data[1].Trim() + ',';
 
                    for ($i = 9; $i -lt $storport_data.Length; $i++) {
                        $original_record += $storport_data[$i].Trim() + ',';
                    }
 
                    #fix for 2012 changing record names
                    if ($header_flag) {
                        $original_record = $original_record.Replace('RequestDuration_100ns', 'RequestDuration in 100ns');
                        $original_record = $original_record.Replace('BuildIoDuration_100ns', 'BuildIoDuration in 100ns');
                        $original_record = $original_record.Replace('StartIoDuration_100ns', 'StartIoDuration in 100ns');
                        $original_record = $original_record.Replace('ByteLengthOfTransfer', 'DataTransferLength');
                    }
 
                    #cleanup
                    $original_record = $original_record.Replace('TimeStamp','DateTime');
                    $original_record = $original_record.TrimEnd(',');
                    $original_record = $original_record.Replace('(',$null);
                    $original_record = $original_record.Replace(')',$null);
                    $original_record = $original_record.Replace("\'",$null);
 
 
                    if (($requestdurationvalue -ne -1) -AND ($header_flag -eq 'false')) {  #write out the data immediately if it is the header or there is no filter (-1 value for $requestdurationvalue)
                        if ([Int64]($storport_data[$request_duration_index].Trim()) -lt ($requestdurationvalue * $requestduration_multiplier)) {
                            #write the line if the value of requestduration is lower then the filter
                            $writer.WriteLine($original_record)
 
                            if ($request_duration_index -eq 9) {
                                #scsi status check
                                if (-Not ($storport_data[$scsi_status_index].Contains("0x00"))) {
                                    $scsi_status_not_0_counter = $scsi_status_not_0_counter + 1;
                                }
 
                                #srb status check
                                if (-Not ($storport_data[$srb_status_index].Contains("0x01"))) {
                                    $srb_status_not_1_counter = $srb_status_not_1_counter + 1;
                                }
                            }
 
                            else {
 
                                #scsi status check
                                if ($storport_data[$scsi_status_index].Trim() -ne "0") {
                                    $scsi_status_not_0_counter = $scsi_status_not_0_counter + 1;
                                }
 
                                #srb status check
                                if ($storport_data[$srb_status_index].Trim() -ne "1") {
                                    $srb_status_not_1_counter = $srb_status_not_1_counter + 1;
                                }
                            }
                        }
                    }
                    else {
                        if ($header_flag -eq 'true') {
                            if ($already_wrote_header -eq 'false') {
                                $writer.WriteLine($original_record)
                            }
 
                            $already_wrote_header = 'true';
                        }
                        else {
                            $writer.WriteLine($original_record)
 
                            if ($request_duration_index -eq 9) {
                                #scsi status check
                                if (-Not ($storport_data[$scsi_status_index].Contains("0x00"))) {
                                    $scsi_status_not_0_counter += 1;
                                }
 
                                #srb status check
                                if (-Not ($storport_data[$srb_status_index].Contains("0x01"))) {
                                    $srb_status_not_1_counter += 1;
                                }
                            } else {
                                #scsi status check                       
                                if ($storport_data[$scsi_status_index].Trim() -ne "0") {
                                    $scsi_status_not_0_counter += 1;
                                }
 
                                #srb status check
                                if ($storport_data[$srb_status_index].Trim() -ne "1") {
                                    $srb_status_not_1_counter += 1;
                                }
                            }
                        }
                    }
                }
            }
 
            $writer.Flush()
            $writer.Close()
            $reader.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show('There was an error while scrubbing the data. The error message is ' + $_.Exception.Message)
            exit
        }
 
        if ($record_counter -ne 0) {
            # open exel spreadsheet
            Write-Progress -Activity "StorportPACMAN Progress" -Status "Opening Excel Spreadsheet" -PercentComplete "66" 
 
            if ($requestduration_multiplier -eq 10000) { #Check for Windows 2012
                $workbookpath = $storportpacmandirectory + '\storport2012.xlsx'
            } else {
                $workbookpath = $storportpacmandirectory + '\storport2008.xlsx'
            }
 
            Try {
                $excel = New-Object -ComObject Excel.Application
                $excel.visible = $true
                $workbook = $excel.workbooks.open($workbookpath)
                $workbook.refreshall()
 
                $mymessage = "Data Refresh Complete. Processed " + $record_counter.ToString() + " records.";
 
                if ($scsi_status_not_0_counter -ne 0) {
                    $mymessage = $mymessage + "`r`nWARNING: there were " + $scsi_status_not_0_counter.ToString() + " records that have a SCSI Status other than GOOD - please review the data.";
                }
 
                if ($srb_status_not_1_counter -ne 0) {
                    $mymessage = $mymessage + "`r`nWARNING: there were " + $srb_status_not_1_counter.ToString() + " records that have a SRB Status of not completing successfully - please review the data.";
                }
 
                [System.Windows.Forms.MessageBox]::Show($mymessage);
            } catch {
                [System.Windows.Forms.MessageBox]::Show('There was an error opening one of the spreadsheets. Make sure both storport2012.xlsx and storport2008.xlsx are in the ' + $storportpacmandirectory + ' directory.  The error message is ' + $_.Exception.Message)
                exit
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show('There was no Storport data in the ETL file.  Please check how you ran the Storport trace.')
            exit
        }
    }
}
