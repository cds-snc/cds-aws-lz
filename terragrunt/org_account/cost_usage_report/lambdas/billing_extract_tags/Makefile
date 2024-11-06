default: 
	python3 main.py

fmt:
	black . $(ARGS)

install:
	pip3 install --user -r requirements_dev.txt

lint:
	flake8 main.py

test:
	python -m pytest -s -vv .

.PHONY: \
	fmt \
	install	\
	lint \
	test