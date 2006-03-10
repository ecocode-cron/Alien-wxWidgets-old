#!/usr/bin/perl -w

BEGIN { our $NO_INIT = 1 }

use strict;
use FindBin;
use lib "$FindBin::RealBin/inc";
use lib "$FindBin::RealBin/lib"; # for Alien::wxWidgets::Utility
use My::Build;

my $build = My::Build->new
  ( module_name     => 'Alien::wxWidgets',
    license         => 'perl',
    author          => 'Mattia Barbon <mbarbon@cpan.org>',
    requires        => { 'File::Spec'                     => '0.80',
                         'Module::Build'                  => '0.26',
                         'Module::Pluggable'              => '2.6',
                        },
    get_options     => { debug      => { type => '!' },
                         unicode    => { type => '!' },
                         mslu       => { type => '!' },
                         static     => { type => '!' },
                         build_wx   => { type => '!' },
                        },
  );

my $build_wx = defined $build->args( 'build_wx' )
                   ? $build->args( 'build_wx' )
                   : $build->y_n( 'Do you want to build wxWidgets?', 'no' );
$build->notes( 'build_wx' => $build_wx );
$build->notes( 'build_data' => do 'patches/data' );

$build->create_build_script;
