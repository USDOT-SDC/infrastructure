import subprocess
import sys
import os
import shutil
import datetime

# move us to where this file is located
abspath = os.path.abspath(__file__)
d_name = os.path.dirname(abspath)
os.chdir(d_name)

# send all stdout to the log file
sys.stdout = open("deploy.log", 'a')

def log_it(log):
    print(datetime.datetime.today().strftime('%Y-%m-%d %H:%M:%S') + ": " + str(log))

def get_dirs():
    # some directories
    if os.name == 'nt':
        bin_dir = 'Scripts'
        lib_dir = 'Lib'
    else:
        bin_dir = 'bin'
        lib_dir = 'lib/python3.11'
    repo_dir = os.path.split(os.getcwd())[-1]
    return {'bin': bin_dir, 'lib': lib_dir, 'repo': repo_dir}


def copyanything(src, dst):
    if os.path.isfile(src):
        shutil.copy2(src, dst)
    elif os.path.isdir(src):
        shutil.copytree(src=src, dst=dst, dirs_exist_ok=True)
    else: raise


# must run Python 3.11.x
if not (sys.version_info.major == 3 and sys.version_info.minor == 11):
    raise EnvironmentError("Python must be version 3.11.x")

# get the bin/scripts dirs
dirs = get_dirs()

print('================================================================================')
keep_file = "keep-this-venv"
venv_dir = ".venv"
if not os.path.exists(keep_file):
    log_it("The " + keep_file + " file was not found, so venv will be rebuilt.")
    log_it('Creating virtual environment...')
    shutil.rmtree("venv", ignore_errors=True)
    subprocess.check_call([sys.executable, "-m", "venv", venv_dir, "--copies", "--clear"])
    log_it('Creating virtual environment...Done')
    # upgrade pip
    log_it('Upgrading pip...')
    path_to_executable = os.path.join(os.getcwd(), venv_dir, dirs['bin'], "python")
    subprocess.check_call([path_to_executable, "-m", "pip", "install", "--upgrade", "pip"])
    log_it('Upgrading pip...Done')
    # upgrade setuptools
    log_it('Upgrading setuptools...')
    subprocess.check_call([path_to_executable, "-m", "pip", "install", "--upgrade", "setuptools"])
    log_it('Upgrading setuptools...Done')
    # install requirements.txt
    log_it('Installing requirements...')
    path_to_requirements = os.path.join(os.getcwd(), "requirements.txt")
    subprocess.check_call([path_to_executable, "-m", "pip", "install", "-r", path_to_requirements, "--upgrade"])
    log_it('Installing requirements...Done')
    file = open(keep_file, 'w+')
    file.close()
else:
    log_it("The " + keep_file + " file was found, so venv was not rebuilt.")
    log_it("Delete the " + keep_file + " file to rebuild the venv.")

# collect the deployment package contents
log_it('Collecting deployment package contents...')

# delete existing
dst_path = os.path.join(os.getcwd(), "deployment-package")
shutil.rmtree(dst_path, ignore_errors=True)
os.makedirs(dst_path)

# set paths
dp_paths = [
    {"src": os.path.join(os.getcwd(), "lambda_function.py"), "dst": os.path.join(dst_path, "lambda_function.py")},
    {"src": os.path.join(os.getcwd(), venv_dir, dirs['lib'], "site-packages", "pytz"), "dst": os.path.join(dst_path, "pytz")},
    {"src": os.path.join(os.getcwd(), venv_dir, dirs['lib'], "site-packages", "yaml"), "dst": os.path.join(dst_path, "yaml")},
]

# copy to deployment-package
for dp_path in dp_paths:
    copyanything(src=dp_path['src'], dst=dp_path['dst'])
log_it('Collecting deployment package contents...Done')

# create deployment package
log_it('Creating deployment package...')
shutil.make_archive(os.path.join(os.getcwd(), "deployment-package"), 'zip', dst_path)
log_it('Creating deployment package...Done')
print('================================================================================')
sys.stdout.close()
