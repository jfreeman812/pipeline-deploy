#!/bin/bash
venv_loc=$(pipenv --venv)
syntribos_root="${venv_loc}/.syntribos"
example_templates="${syntribos_root}/templates/example"
mkdir -p "${example_templates}"
sed -i "s#VENV_PATH#${venv_loc}#g" syntribos.conf
cp ./syntribos.conf "${syntribos_root}"
cp ./examples/templates/example_get.template "${example_templates}"
