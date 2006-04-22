#!/usr/bin/perl -w

BEGIN { our $NO_INIT = 1 }

use strict;
use FindBin;
use lib "$FindBin::RealBin/lib", "$FindBin::RealBin/inc";
use My::Build;

# new_from_context is broken: it does not restore
# @INC set in Build.PL before trying to load a base class not
# defined using ->subclass...
my $class = Module::Build->subclass
  ( class            => 'My::Build::new_from_context_is_broken',
    code             => <<'EOC' );
use lib qw(lib inc);
use My::Build;
@ISA = qw(My::Build);
EOC
my $build = $class->new
  ( module_name     => 'Alien::wxWidgets',
    license         => 'perl',
    author          => 'Mattia Barbon <mbarbon@cpan.org>',
    requires        => { perl                             => '5.6',
                         'Module::Pluggable'              => '2.6',
                        },
    build_requires  => { 'Module::Build'                  => '0.26',
                         },
    get_options     => { debug      => { type => '!' },
                         unicode    => { type => '!' },
                         mslu       => { type => '!' },
                         static     => { type => '!' },
                         monolithic => { type => '!' },
                         build_wx   => { type => '!' },
                        },
  );

my $build_wx = defined $build->args( 'build_wx' )
                   ? $build->args( 'build_wx' )
                   : $build->y_n( 'Do you want to build wxWidgets?', 'no' );
$build->notes( 'build_wx' => $build_wx );
$build->notes( 'build_data' => do 'patches/data' );

$build->create_build_script;

unlink 'configured' if -f 'configured';
