#!/usr/bin/perl -w

BEGIN { our $NO_INIT = 1 }

use strict;
use lib "lib", "inc";
use My::Build;

our $TYPE;

# new_from_context is broken: it does not restore
# @INC set in Build.PL before trying to load a base class not
# defined using ->subclass...
my $class = Module::Build->subclass
  ( class            => 'My::Build::new_from_context_is_broken',
    code             => <<'EOC' );
use lib qw(lib inc);
@ISA = qw(My::Build Module::Build);
require My::Build;
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
                         source     => { type => '=s' },
                         },
    create_makefile_pl => 'passthrough',
  );

my $build_wx = _askyn( $build, 'build_wx',
                       'Do you want to build wxWidgets?', 'no' );
$build->notes( 'build_wx' => $build_wx );
if( $build_wx ) {
    $TYPE = _ask( $build, 'source', 'Which archive type?', 'tar.gz' );
    $build->notes( 'build_data' => do 'patches/data' );
}

$build->create_build_script;

sub _askyn {
    my( $build, $arg, $question, $default ) = @_;
    my $res = defined $build->args( $arg )
                  ? $build->args( $arg )
                  : $build->y_n( $question, $default );

    return $res
}

sub _ask {
    my( $build, $arg, $question, $default ) = @_;
    my $res = defined $build->args( $arg )
                  ? $build->args( $arg )
                  : $build->prompt( $question, $default );

    return $res
}
