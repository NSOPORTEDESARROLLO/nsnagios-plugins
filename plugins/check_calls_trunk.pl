#!/usr/bin/perl 

use Asterisk::AMI;
use Getopt::Long qw(GetOptions);


sub help {

print "
Error: Script usage:\ncheck_calls_trunk --port 5038 --user some_user --pwd password --trunk trunh_name -f 30 -w 10 -c 20\n

Where:
	--port = Asterisk ami port
	--host = Asterisk ami host or IP
	--user = Asterisk ami user 
	--pwd = Asterisk ami password
	--trunk = Trunk name to check channels
	-f = Max calls by trunks, for example PRI E1 29
	-w = Warning value (numeric)
	-c = Critical value (Numeric)

Critical must be greater than Warning value and full value must be grater than Critical and Warning value.\n";


exit 3;	


}


GetOptions ('trunk=s' => \$trunk,
	'user=s' => \$user,
	'pwd=s' => \$pwd,
	'host=s' => \$host,
	'port=s' => \$port,
	'w=s' => \$w,
	'c=s' => \$c,
	'f=s' => \$f
	
	);


#Validar informacion 
if ($trunk eq ""  && $user eq ""  && $pwd eq "" && $host eq "" && $f eq "" && $w eq "" && $c eq "") {

	help();

}
	


my $astman = Asterisk::AMI->new(PeerAddr => $host,
                                PeerPort => $port,
                                Username => $user,
                                Secret => $pwd
                        );
 
die "Unable to connect to asterisk" unless ($astman);
 
my $action = $astman->send_action({ Action => 'Command',
                         Command => 'sip show channels'
                        });

my $resp = $astman->get_response($action);

my $CMD=%{ $resp }{'CMD'};

my @SP=grep(/$trunk/, @{$CMD});
my @FILTER=grep(!/nothing/, @SP);

my $channels = 0;

for my $line (@FILTER) {

	#print "$line\n";

	$channels++;
}


#Desconecto de AMI
$astman->disconnect();




#Logica para NAGIOS
my $code=0;
my $state="Ok";
my $msg; 

#Critical must be greater than warning value 
if ( $w >= $c ) {

	help()
} 



#Critical 
if ( $channels >= $c ) {

	$code=2;
	$state="Critical"; 

} else {

	if ( $channels >= $w ) {


		$code=1;
		$state="Warning";


	}




}


#Imprime salida Nagios
print "$state: $channels call(s) on trunk $trunk |CALLS=$channels;$w;$c;0;$f";
exit $code;

