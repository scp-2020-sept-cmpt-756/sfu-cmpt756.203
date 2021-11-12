#
# Front-end to bring some sanity to the litany of tools and switches
# in calling the sample application from the command line.
#
# This file is for operations that work on all cloud vendors
# supported in the class

# --- ls: List any clusters on every vendor
ls:
	@make -f k8s.mak showcontext --no-print-directory
	@echo
	@echo "Azure (az.mak):"
	@make -f az.mak lsnc --no-print-directory
	@echo
	@echo "AWS (eks.mak):"
	@make -f eks.mak lscl --no-print-directory
	@echo
	@# We do not support GCP from this container
	@#echo "GCP (gcp.mak):"
	@#make -f gcp.mak lsnc --no-print-directory
	@#echo
	@echo "DynamoDB tables, read units, and write units"
	@make -f k8s.mak ls-tables --no-print-directory
	@echo
	@echo "Background Gatling jobs running"
	@tools/list-gatling.sh
	@echo
	@echo 'Run "kill -9 PROCESS-ID-LIST" to terminate the Gatling jobs'
	@echo
