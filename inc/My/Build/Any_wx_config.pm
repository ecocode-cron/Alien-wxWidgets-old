package My::Build::Any_wx_config;

use strict;

our @ISA;

my $libs_sep;
my @LIBRARIES = qw(base net xml adv animate core deprecated fl gizmos
                   html media mmedia ogl plot qa stc svg xrc);

BEGIN {
    my $wx_config = $ENV{WX_CONFIG} || 'wx-config';
    my $ver = `$wx_config --version`;
    $ver =~ m/^(\d)\.(\d)/;
    $ver = $1 + $2 / 1000;

    if( $ver >= 2.005 ) {
        $libs_sep = `$wx_config --libs base > /dev/null 2>&1 || echo 'X'` eq "X\n" ?
          '=' : ' ';
        require My::Build::Any_wx_config_Bakefile;
        @ISA = qw(My::Build::Any_wx_config_Bakefile);
    } else {
        require My::Build::Any_wx_config_Tmake;
        @ISA = qw(My::Build::Any_wx_config_Tmake);
    }
}

package My::Build::Any_wx_config::Base;

use strict;
use base qw(My::Build::Base);
use Config;

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;
    my $cf = $self->wx_config( 'cxxflags' );

    $cf =~ m/__WX(x11|msw|motif|gtk|mac)__/i or
      die "Unable to determine toolkit!";

    $config{config}{toolkit} = lc $1;
    $config{compiler} = $ENV{CXX} || $self->wx_config( 'cxx' );
    if( $self->awx_debug ) {
        $config{c_flags} .= ' -g ';
    }

    my $cccflags = $self->wx_config( 'cxxflags' );
    my $libs = $self->wx_config( 'libs' );

    foreach ( split /\s+/, $cccflags ) {
        m(^[-/]I) && do { $config{include_path} .= "$_ "; next; };
        m(^[-/]D) && do { $config{defines} .= "$_ "; next; };
        $config{c_flags} .= "$_ ";
    }

    foreach ( split /\s+/, $libs ) {
        m{^-[lL]|/} && do { $config{link_libraries} .= " $_"; next; };
        if( $_ eq '-pthread' && $^O =~ m/linux/i ) {
            $config{link_libraries} .= " -lpthread";
            next;
        }
        $config{link_libraries} .= " $_";
    }

    $config{_libraries} = {};
    my $arg = 'libs' . $libs_sep . join ',', grep { !m/base/ } @LIBRARIES;
    my $libraries = $self->_call_wx_config( $arg );

    foreach my $lib ( grep { m/\-lwx/ } split ' ', $libraries ) {
        $lib =~ m/-l(.*_(\w+)-.*)/ or die $lib;
        my( $key, $name ) = ( $2, $1 );
        $key = 'base' if $key =~ m/^base[ud]{0,2}/;
        $key = 'base' if $key =~ m/^carbon/; # here for Mac
        $config{_libraries}{$key} = { dll  => "lib${name}.$Config{dlext}",
                                      link => $lib };
    }

    return %config;
}

sub _call_wx_config {
    my $self = shift;
    my $options = join ' ', map { "--$_" } @_;
    my $wx_config = $ENV{WX_CONFIG} || 'wx-config';

    # not completely correct, but close
    $options = "--static $options" if $self->awx_static;

    my $t = qx($wx_config $options);
    chomp $t;

    return $t;
}

1;
