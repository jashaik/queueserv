queueserv
=====

Queue server is an Erlang OTP application built using gen_tcp behaviour.

Build
-----

    $ rebar3 compile
    
Server
------
1. clone the source code `git clone https://github.com/jashaik/queueserv.git`
2. Go to `_build/default/rel/queueserv/` and start the service. 
`
   $ bin/queueserv daemon
 `
 
Client
------
1. Connect to the TCP port using `telnet 127.0.0.1 4001`
2. You can see the Welcome message with supported messages. Currently it can serve `'in:payload' or 'out'`
    
<img width="483" alt="Screenshot 2022-04-10 at 9 02 04 PM" src="https://user-images.githubusercontent.com/76031665/162627155-733a8014-2658-4b3f-b819-36ef737948be.png">

Example
-------
<img width="434" alt="Screenshot 2022-04-10 at 9 03 41 PM" src="https://user-images.githubusercontent.com/76031665/162627213-ae150988-b2ff-463b-872b-eaa143668c69.png">
