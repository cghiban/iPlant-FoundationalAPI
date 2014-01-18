
How to run the examples
-----------------------

To get a list of your files and other stuff:

	perl examples/test-io.pl

This does a few things: creates a directory, renames it, 
removed it and uploads a new file to your root folder.

To download a file:

	perl examples/test-io-download-file.pl Bx_2.fa

To get submit an app:

	perl examples/test-apps.pl <app-id|app-name> <file from data store>
    perl examples/test-apps.pl wca-1.00 /ghiban/Bx_51.fa
	perl examples/test-apps.pl wc /ghiban/numbers.txt

To check on a job's status:

	perl examples/test-job.pl <job-id>
	perl examples/test-job.pl 0001384479702920-5056831b44-0001-007

To list your jobs:

	perl examples/test-job.pl

