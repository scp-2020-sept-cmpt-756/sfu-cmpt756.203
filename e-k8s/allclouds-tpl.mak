#
# Front-end to bring some sanity to the litany of tools and switches
# in calling the sample application from the command line.
#
# This file is for operations that work on all cloud vendors
# supported in the class

# --- ls: List any clusters on every vendor
ls:
	@make -f k8s.mak showcontext
	@echo
	@echo "Azure (az.mak):"
	@make -f az.mak lsnc
	@echo
	@echo "AWS (eks.mak):"
	@make -f eks.mak lscl
	@echo
	@echo "GCP (gcp.mak):"
	@make -f gcp.mak lsnc
	@echo
