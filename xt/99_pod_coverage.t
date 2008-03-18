use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok( { also_private => [ qr/^(handler|do|DEBUG|EOL|command|dispatch|enqueue|dequeue|command|establish|goto|map|send|Set_Blocking|FTP_)/ ] } );
