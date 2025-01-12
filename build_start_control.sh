#!/bin/bash
# build and start script  



rm -rf erl_cra* rebar3_crashreport;
rm -rf *~ */*~ */*/*~ */*/*/*~;
rm -rf control
git clone https://github.com/joq62/control.git
cd control
rm -rf _build
rebar3 release
./_build/default/rel/control/bin/control daemon
#./_build/default/rel/control/bin/control foreground
