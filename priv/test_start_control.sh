#!/bin/bash
# test script  

# path_to_release_exec=$1
# mode=$2, mode daemon | foreground


rm -rf erl_cra* rebar3_crashreport;
rm -rf *~ */*~ */*/*~ */*/*/*~;
#rm -rf control
#git clone 
#cd $1
rm -rf add_test
rm -rf _build
rebar3 release
./_build/default/rel/control/bin/control daemon
#./_build/default/rel/control/bin/control foreground
