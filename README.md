
# BashDumpsterDiver

This little bash script is intended to scan a set of files for secrets (e.g. Hashes, Passwords, etc.) by means of an entropy analysis of the files' contents. It was inspired by the Python project [DumpsterDiver](https://github.com/securing/DumpsterDiver) by securing and offers similar functionality but more flexibility in terms of compatibility as it is written in pure Bash. 

The script writes any status messages to stderr. As shown below, the analysis is started by executing the start.sh script and interrupted using the stop.sh script.


## Usage
```
usage: ./start.sh [-h] [-e] [-v] [-b] [-c <threads>] [-d <path>] [-l <number>] [-m <number>] [-t <number>] 

Switches:
	
-h 
	Prints the help message
-b
	By specifying this switch, binaries are also scanned when searching for secrets. (Default: disabled)
-e
	Enables extensive verbosity. (Default: disabled)
-v 
	Enables basic verbosity. (Default: disabled)
-d <path>
	Specifies the starting path at which the recursive search is started. (Default: "/")
-l <integer>
	Minimum length of the strings to be considered for the entropy calculation. (Default: 12)
-m <integer>
	Maximum length of the strings to be considered for the entropy calculation. (Default: 80)
-t <float>
	Specifies the entropy threshold above which strings are recognized as secrets. (Default: 4.0)
-c <threads>
	Specifies the number of threads used for analysis. (Default: 2)
-o <output dir>
	Specifies the output directory where all results are written to. (Default: /tmp)


```
