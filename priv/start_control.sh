#!/bin/bash
# assumes that the release is not started

# path_to_release_exec=$1
# mode=$2, mode daemon | foreground


rm -rf erl_cra* rebar3_crashreport;
rm -rf *~ */*~ */*/*~ */*/*/*~;
rm -rf control
git clone 
cd $1
rebar3 release
cd ..
