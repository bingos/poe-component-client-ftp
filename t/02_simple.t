use strict;
use warnings;
use Test::More tests => 22;
#sub POE::Component::Client::FTP::DEBUG () { 1 }
use POE qw(Component::Client::FTP Filter::Line);
use Test::POE::Server::TCP;

my %tests = (
   'USER anonymous' 	=> '331 Any password will work',
   'PASS anon@anon.org' => '230 Any password will work',
   'PWD' 		=> '257 "/pub/CPAN" is current directory.',
   'NOOP'		=> '200 NOOP command successful',
   'TYPE A'		=> '200 Type set to A',
   'CWD /pub/CPAN'	=> '250 CWD command successful.',
   'QUIT' 		=> '221 Goodbye.',
);

POE::Session->create(
   package_states => [
	main => [qw(
			_start 
			_stop
			testd_registered 
			testd_connected
			testd_disconnected
			testd_client_input
			connected
			authenticated
			pwd
			cd
			noop
			type
		)],
   ],
   heap => { tests => \%tests, types => [ [ '200', 'Type set to A' ], [ '200', 'Type set to I' ] ] },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
#    filter => POE::Filter::Line->new,
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{remote_port} = $port;
  return;
}

sub _stop {
  pass("Done");
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::Client::FTP->spawn(
        Alias => 'ftpclient' . $_[SESSION]->ID(),
        Username => 'anonymous',
        Password => 'anon@anon.org',
        RemoteAddr => '127.0.0.1',
	RemotePort => $heap->{remote_port},
        Events => [qw(
			connected 
			connect_error 
			authenticated 
			login_error 
			pwd
			pwd_error
			cd
			cd_error
			noop
			noop_error
			type
			type_error
			get_error 
			get_data 
			get_done
		  )],
        Filters => { get => POE::Filter::Line->new(), },
  );
  return;
}

sub testd_connected {
  my ($kernel,$heap,$id,$client_ip,$client_port,$server_ip,$server_port) = @_[KERNEL,HEAP,ARG0..ARG4];
  diag("$client_ip,$client_port,$server_ip,$server_port\n");
  my @banner = (
	'220---------- Welcome to Pure-FTPd [privsep] ----------',
	'220-You are user number 228 of 1000 allowed.',
	'220-Local time is now 18:46. Server port: 21.',
	'220-Only anonymous FTP is allowed here',
	'220 You will be disconnected after 30 minutes of inactivity.',
  );
  pass("Client connected");
  $heap->{testd}->send_to_client( $id, $_ ) for @banner;
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($input);
  if ( defined $heap->{tests}->{ $input } ) {
     pass($input);
     my $response = delete $heap->{tests}->{ $input };
     $heap->{testd}->disconnect( $id ) unless scalar keys %{ $heap->{tests} };
     $heap->{testd}->send_to_client( $id, $response );
  }
  return;
}

sub testd_disconnected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass("Disconnected");
  $heap->{testd}->shutdown();
  return;
}

sub connected {
  my ($numeric,$message) = @_[ARG0,ARG1];
  ok( $numeric eq '220', 'Correct connection numeric' );
  ok( $message eq 'You will be disconnected after 30 minutes of inactivity.', $message );
  return;
}

sub authenticated {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '230', 'Correct authentication numeric' ); 
  ok( $message eq 'Any password will work', $message );
  $kernel->post( $sender, 'noop' );
  return;
}

sub noop {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '200', 'Correct authentication numeric' ); 
  ok( $message eq 'NOOP command successful', $message );
  $kernel->post( $sender, 'type', 'A' );
  return;
}

sub type {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '200', 'Correct type numeric' ); 
  ok( $message eq 'Type set to A', $message );
  $kernel->post( $sender, 'cd', '/pub/CPAN' );
  return;
}

sub cd {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '250', 'Correct cwd numeric' ); 
  ok( $message eq 'CWD command successful.', $message );
  $kernel->post( $sender, 'pwd' );
  return;
}

sub pwd {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '257', 'Correct pwd numeric' ); 
  ok( $message eq '"/pub/CPAN" is current directory.', $message );
  $kernel->post( $sender, 'quit' );
  return;
}

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     return 0 if $event eq '_child';
     my @output = ( "$event: " );

     for my $arg (@$args) {
         if ( ref $arg eq 'ARRAY' ) {
             push( @output, '[' . join(' ,', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     print join ' ', @output, "\n";
     return 0;
 }
