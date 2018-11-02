#!/bin/bash

# Set various variables for use below
venvLoc=$(pipenv --venv)
syntribosRoot="${venvLoc}/.syntribos"
templateDir="${syntribosRoot}/templates"
exampleTemplates="${templateDir}/example"
orcaTemplates="${templateDir}/orca"
raxTemplates="${templateDir}/rax"

# Create the necessary folders
mkdir -p "${exampleTemplates}"
mkdir -p "${orcaTemplates}"
mkdir -p "${raxTemplates}"

# Replace config file variables with virtual environment path
sed -i "s#VENV_PATH#${venvLoc}#g" *.conf

# Copy files to proper locations in the syntribos root directory
cp -r ./*.conf "${syntribosRoot}"
cp -r ./examples/templates/* "${exampleTemplates}"
cp -r ./rax-templates/* "${raxTemplates}"
cp -r ./orca-templates/* "${orcaTemplates}"
