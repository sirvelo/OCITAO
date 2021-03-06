eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

# -*- perl -*-

use lib "$ENV{ACE_ROOT}/bin";
use PerlACE::TestTarget;
use File::stat;

$status = 0;
$debug = 0;

my $ns = PerlACE::TestTarget::create_target (1) || die "Create target 1 failed\n";
my $sv = PerlACE::TestTarget::create_target (2) || die "Create target 2 failed\n";
my $cl = PerlACE::TestTarget::create_target (3) || die "Create target 3 failed\n";

# amount of delay between running the servers

$sleeptime = 10;

$nsiorfile = "ns.ior";
$inputfile = "test_input";

# generate test stream data
# the size of this file is limited by the maximum packet size
# windows has a maximum size of 8KB
$inputfile = PerlACE::generate_test_file($inputfile, 32000);
my $cl_inputfile = $cl->LocalFile ($inputfile);

my $ns_nsiorfile = $ns->LocalFile ($nsiorfile);
my $sv_nsiorfile = $sv->LocalFile ($nsiorfile);
my $cl_nsiorfile = $cl->LocalFile ($nsiorfile);
$ns->DeleteFile ($nsiorfile);
$sv->DeleteFile ($nsiorfile);
$cl->DeleteFile ($nsiorfile);

if ($cl->PutFile ($inputfile) == -1) {
    print STDERR "ERROR: cannot set file <$cl_inputfile>\n";
    exit 1;
}

@protocols = ("TCP",
              "UDP"
             );

for ($i = 0; $i <= $#ARGV; $i++) {
    if ($ARGV[$i] eq "-h" || $ARGV[$i] eq "-?") {
        print STDERR "\nusage:  run_test\n";

        print STDERR "\t-h shows options menu\n";

        print STDERR "\t-d: Debug Level defaults to 0";

        print STDERR "\n";

        exit;
    }
    elsif ($ARGV[$i] eq "-d") {
        $debug = $ARGV[$i + 1];
        $i++;
    }
}

$NS = $ns->CreateProcess ("$ENV{TAO_ROOT}/orbsvcs/Naming_Service/tao_cosnaming",
                          " -o $ns_nsiorfile");

print STDERR "Starting Naming Service\n";

$NS_status = $NS->Spawn ();

if ($NS_status != 0) {
    print STDERR "ERROR: Name Service returned $NS_status\n";
    exit 1;
}

if ($ns->WaitForFileTimed ($nsiorfile,$ns->ProcessStartWaitInterval()+45) == -1) {
    print STDERR "ERROR: cannot find file <$ns_nsiorfile>\n";
    $NS->Kill (); $NS->TimedWait (1);
    exit 1;
}

if ($ns->GetFile ($nsiorfile) == -1) {
    print STDERR "ERROR: cannot retrieve file <$ns_nsiorfile>\n";
    $NS->Kill (); $NS->TimedWait (1);
    exit 1;
}
if ($sv->PutFile ($nsiorfile) == -1) {
    print STDERR "ERROR: cannot set file <$sv_nsiorfile>\n";
    $NS->Kill (); $NS->TimedWait (1);
    exit 1;
}
if ($cl->PutFile ($nsiorfile) == -1) {
    print STDERR "ERROR: cannot set file <$cl_nsiorfile>\n";
    $NS->Kill (); $NS->TimedWait (1);
    exit 1;
}

$outputfile = "TCP_output";

for $protocol (@protocols) {
    if ($protocol eq "RTP/UDP") {
        $outputfile = "RTP_output";
    }
    else {
        $outputfile = $protocol."_output";
    }

    my $sv_outputfile = $sv->LocalFile ($outputfile);
    $ns->DeleteFile ($outputfile);

    $SV = $sv->CreateProcess ("server",
                              "-ORBInitRef NameService=file://$sv_nsiorfile ".
                              "-ORBDebugLevel $debug ".
                              "-f $sv_outputfile");

    $CL = $cl->CreateProcess ("ftp",
                              "-ORBInitRef NameService=file://$cl_nsiorfile ".
                              "-ORBDebugLevel $debug ".
                              "-f $cl_inputfile");

    print STDERR "Using ".$protocol."\n";
    print STDERR "Starting Server\n";

    $SV_status = $SV->Spawn ();
    if ($SV_status != 0) {
        print STDERR "ERROR: server returned $SV_status\n";
        $SV->Kill (); $SV->TimedWait (1);
        $NS->Kill (); $NS->TimedWait (1);
        exit 1;
    }
    sleep $sleeptime;

    print STDERR "Starting Client\n";

    $CL_status = $CL->SpawnWaitKill ($cl->ProcessStartWaitInterval()+185);
    if ($CL_status != 0) {
        print STDERR "ERROR: ftp returned $CL_status\n";
        $status = 1;
    }

    $SV_status = $SV->TerminateWaitKill ($sv->ProcessStopWaitInterval()+185);
    if ($SV_status != 0) {
        print STDERR "ERROR: server returned $SV_status\n";
        $status = 1;
    }

    $ns->DeleteFile ($outputfile);
}

$NS_status = $NS->TerminateWaitKill ($ns->ProcessStopWaitInterval());
if ($NS_status != 0) {
    print STDERR "ERROR: Naming Service returned $NS_status\n";
    $status = 1;
}

$ns->DeleteFile ($nsiorfile);
$sv->DeleteFile ($nsiorfile);
$cl->DeleteFile ($nsiorfile);
$cl->DeleteFile ($inputfile);

exit $status;
