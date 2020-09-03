import os
from shutil import copyfile
from zipfile import ZipFile

plugins_dir = "plugins"
luts_dir = "luts"
macros_dir = "macros"
ij_path = "ij.jar"

MANIFEST = '''Manifest-Version: 1.0
Ant-Version: Apache Ant 1.10.1
Created-By: 1.8.0_172-b11 (Oracle Corporation)
'''

CHEERPJ_DIR = os.environ.get("CHEERPJ_DIR")

print('====> Building plugin list...')
for root, dirs, files in os.walk(plugins_dir, topdown=False):
    for name in files:
        filename = os.path.join(root, name)
        
        if CHEERPJ_DIR and name.endswith('.class'):
            print("====> Compiling " + filename)
            with ZipFile(filename.replace('.class', '.jar'), 'w') as zip:
                zip.writestr('META-INF/MANIFEST.MF', MANIFEST)
                zip.write(filename, arcname=name)
            # escape $ sign
            filename = filename.replace('$', '\$')
            os.system(CHEERPJ_DIR + '/cheerpjfy.py --deps=' +ij_path+ " "+ filename.replace('.class', '.jar'))
            os.system('rm ' + filename.replace('.class', '.jar'))
            os.system('mv ' + filename.replace('.class', '.jar.js') + ' ' + filename.replace('.class', '.js'))
        elif os.path.relpath(filename, plugins_dir).startswith('jars') and name.endswith('.jar'):
            # with ZipFile(jar_file_name, 'w') as zip:
            #     zip.writestr('META-INF/MANIFEST.MF', MANIFEST)
            #     zip.write(filename, arcname=name)
            print("====> Compiling " + filename)
            os.system(CHEERPJ_DIR + '/cheerpjfy.py '+ filename)
        else:
            print('====> Skipping '+ filename)

# building index.list
def index_dir(cdir):
    with open(os.path.join(cdir, 'index.list'), 'w') as index:
        for file_name in os.listdir(cdir):
            fname = os.path.splitext(file_name)[0]
            if os.path.isfile(os.path.join(cdir, file_name)):
                if file_name.endswith('.class') and os.path.exists(os.path.join(cdir, fname+".js")):
                    print('Adding ' + os.path.join(cdir, file_name))
                    index.write(file_name+"\n")
                if file_name.endswith('.jar')  and os.path.exists(os.path.join(cdir, fname+".jar.js")):
                    print('Adding ' + os.path.join(cdir, file_name))
                    index.write(file_name+"\n")
                if file_name.endswith('.ijm') or file_name.endswith('.lut'):
                    print('Adding ' + os.path.join(cdir, file_name))
                    index.write(file_name+"\n")
            elif os.path.isdir(os.path.join(cdir, file_name)):
                index.write(file_name+"\n")
            
print('====> Building index.list for ' + os.path.abspath(plugins_dir))

for d in [plugins_dir, luts_dir, macros_dir]:
    index_dir(d)
    for root, dirs, files in os.walk(d, topdown=False):
        for d in dirs:
            index_dir(os.path.join(root, d))

print('Done')
