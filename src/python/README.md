# Utils

Create a virtual environment using this command:

`python3 -m venv .env`

If it doesn't work:

- Ensure you have pip installed:
	`python3 get-pip.py`
- Create virtualenv:

	```
	python3 -m pip install --user .env
	python3 -m virtualenv .env
	source myenv/bin/activate
	```


When you install a new package, run this command below to update the list of packages required:

`pip freeze | grep -v hexaly > requirements.txt`
`./update_requirements_hexaly.sh`

To install the packages in requirements.txt:

`pip install -r requirements.txt`
`pip install -r requirements-hexaly.txt`
