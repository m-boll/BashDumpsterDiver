
# BashDumpsterDiver

This little bash script is intended to scan a set of files for secrets (e.g. Hashes, Passwords, etc.) by means of an entropy analysis of the files' contents. It was inspired by the Python project XXX and provides a similar functionality. It was inspired by the Python project XXX and offers similar functionality but more flexibility as it is written in Bash.


## Usage
```
usage: ./dumpster_diver.sh [-h] [-v] [-b] [-d <path>] [-l <number>] [-m <number>] [-t <number>] 

Switches:
	
-h 
	Prints the help message
-b
	By specifying this switch, binaries are also scanned when searching for secrets. (Default: disabled)
-d <path>
	Specifies the starting path at which the recursive search is started. (Default: "/")
-l <integer>
	Minimum length of the strings to be considered for the entropy calculation. (Default: 12)
-m <integer>
	Maximum length of the strings to be considered for the entropy calculation. (Default: 70)
-t <float>
	Specifies the entropy threshold above which strings are recognized as secrets. (Default: 4.0)

```