.PHONY: default, fmt

default: 
	@echo "Commands:"
	@echo "---------"
	@echo "fmt		Format the source code"

fmt: 
	@terraform fmt --recursive
	@terragrunt hclfmt