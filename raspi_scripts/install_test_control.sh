#!/bin/bash
sudo rm -rf control;
sudo rm -rf logs;
git clone https://github.com/joq62/control.git;
erl -pa control/ebin -sname control_a  -setcookie a -run control start;
echo Eagle has wings
