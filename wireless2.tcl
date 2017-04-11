 # aodv1.tcl
# A 3-node example for ad-hoc simulation with AODV

# Define options
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             50                          ;# number of mobilenodes
set val(rp)             AODV                       ;# routing protocol
set val(x)              1000                        ;# X dimension of topography
set val(y)              1000                        ;# Y dimension of topography 
set val(stop)           150                        ;# time of simulation end

set ns            [new Simulator]
set tracefd       [open simple.tr w]
set windowVsTime2 [open win.tr w] 
set namtrace      [open simwrls.nam w]   


$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]

$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

#
#  Create nn mobilenodes [$val(nn)] and attach them to the channel. 
#

# configure the nodes
        $ns node-config -adhocRouting $val(rp) \
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -channelType $val(chan) \
                         -topoInstance $topo \
                         -agentTrace ON \
                         -routerTrace ON \
                         -macTrace OFF \
                         -movementTrace ON
                        
        for {set i 0} {$i < $val(nn) } { incr i } {
                set node_($i) [$ns node]       
        }




# Provide initial location of mobilenodes
for {set i 0} {$i < 50} {incr i} {

set node_($i) [$ns node]
# $node_($i) color red

}

for {set i 0} {$i < 50} {incr i} {

$node_($i) set X_ [expr rand()*$val(x)]
$node_($i) set Y_ [expr rand()*$val(y)]
$node_($i) set Z_ 0

}

$ns color $node_(0) red
$ns color $node_(1) blue


$ns at 0.0 "$node_(0) label SENDER_1"
$ns at 0.0 "$node_(1) label SENDER_2"
$ns at 0.0 "$node_(10) label RECEIVER"

# Generation of movements
for {set i 0} {$i < $val(nn)} {incr i} {
    set xx_ [expr rand()*$val(x)]
    set yy_ [expr rand()*$val(y)]
    set rng_time [expr rand()*$val(stop)]
    $ns at $rng_time "$node_($i) setdest $xx_ $yy_ 15.0"   ;# random movements
}

# Set a TCP connection

set tcp [new Agent/TCP/Newreno]
$ns attach-agent $node_(0) $tcp

set tcp2 [new Agent/TCP/Newreno]
$ns attach-agent $node_(1) $tcp2

$tcp set class_ 2
$tcp2 set class_ 2

set sink [new Agent/TCPSink]
$ns attach-agent $node_(10) $sink

set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns connect $tcp $sink

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns connect $tcp2 $sink


$ns at 5.0 "$ftp start" 
$ns at 10.0 "$ftp2 start" 

# Printing the window size
proc plotWindow {tcpSource file} {
global ns
set time 0.01
set now [$ns now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns at [expr $now+$time] "plotWindow $tcpSource $file" }
$ns at 10.1 "plotWindow $tcp $windowVsTime2" 

# Define node initial position in nam
for {set i 0} {$i < $val(nn)} { incr i } {
# 30 defines the node size for nam
$ns initial_node_pos $node_($i) 30
}

# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$node_($i) reset";
}

# ending nam and the simulation 
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 150.01 "puts \"end simulation\" ; $ns halt"
proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    #Execute nam on the trace file
    exec nam simwrls.nam &
    exit 0
}

#Call the finish procedure after 5 seconds of simulation time
$ns run
