use strict;
use inc::Module::Install;
name 'POE-Component-Client-FTP';
author 'Michael Ching <michaelc@wush.net>';
license 'perl';
version_from 'lib/POE/Component/Client/FTP.pm';
abstract_from 'lib/POE/Component/Client/FTP.pm';
author_tests 'xt';
build_requires 'Test::More' => 0.47;
build_requires 'Test::POE::Server::TCP' => 0.14;
build_requires 'Test::POE::Client::TCP' => 0.08;
perl_version '5.006';
requires 'POE' => 0.38;
my $value = prompt( 'Do you want to enable optional TLS support ( requires POE::Component::SSLify ) [y/N]?', 'N' );
requires 'POE::Component::SSLify' => 0.10 if $value =~ /^y/i;
my $network = prompt( 'Do you want live network tests [N/y]?', 'N' );
if ( $network =~ /^y$/i ) {
  open FH, "> network.tests" or die "$!\n";
  print FH "Bleh\n";
  close FH;
}
clean_files 'network.tests';
makemaker_args(dist => { PREOP => "$^X ./tools/svn-log.perl > ./Changes" });
WriteAll();
