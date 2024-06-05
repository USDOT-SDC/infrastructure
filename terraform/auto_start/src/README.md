# Virtual Environment and Deployment Package Setup

From this directory:
1. Run:
   1. `python -m venv .venv --prompt as`
   1. `.venv\Scripts\activate`
   1. `python.exe -m pip install --upgrade pip setuptools`
   1. `pip install -r requirements.txt`   
   1. `pip install -t . -r requirements-deployment-package.txt`