package My::Build::Any_wx_config;

use strict;

our @ISA = qw(My::Build::Any_wx_config::Base);

our $WX_CONFIG_LIBSEP;
our @LIBRARIES = qw(base net xml adv animate core deprecated fl gizmos
                    html media mmedia ogl plot qa stc svg xrc);

my $initialized;
my( $wx_debug, $wx_unicode );

sub _init {
    return if $initialized;
    $initialized = 1;

    my $wx_config = $ENV{WX_CONFIG} || 'wx-config';
    my $ver = `$wx_config --version` or die "Can't execute wx-config: $!";

    $ver =~ m/^(\d)\.(\d)/;
    $ver = $1 + $2 / 1000;

    my $base = `$wx_config --basename`;
    $wx_debug = $base =~ m/d$/ ? 1 : 0;
    $wx_unicode = $base =~ m/ud?$/ ? 1 : 0;

    if( $ver >= 2.005001 ) {
        $WX_CONFIG_LIBSEP = `$wx_config --libs base > /dev/null 2>&1 || echo 'X'` eq "X\n" ?
          '=' : ' ';
        require My::Build::Any_wx_config_Bakefile;
        @ISA = qw(My::Build::Any_wx_config_Bakefile);
    } else {
        require My::Build::Any_wx_config_Tmake;
        @ISA = qw(My::Build::Any_wx_config_Tmake);
    }

    sub awx_is_debug { $wx_debug }
    sub awx_is_unicode { $wx_unicode }
}

package My::Build::Any_wx_config::Base;

use strict;
use base qw(My::Build::Base);
use Config;

sub awx_configure {
    My::Build::Any_wx_config::_init;

    my $self = shift;
    my %config = $self->SUPER::awx_configure;
    my $cf = $self->wx_config( 'cxxflags' );

    $cf =~ m/__WX(x11|msw|motif|gtk|mac)__/i or
      die "Unable to determine toolkit!";
    $config{config}{toolkit} = lc $1;

    if( $config{config}{toolkit} eq 'gtk' ) {
        $self->wx_config( 'basename' ) =~ m/(gtk2?)/i or
          die 'PANIC: ', $self->wx_config( 'basename' );
        $config{config}{toolkit} = lc $1;
    }

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

    my @paths = ( ( map { s/^-L//; $_ } grep { /^-L/ } split ' ', $libs ),
                  qw(/usr/local/lib /usr/lib) );

    foreach ( split /\s+/, $libs ) {
        m{^-[lL]|/} && do { $config{link_libraries} .= " $_"; next; };
        if( $_ eq '-pthread' && $^O =~ m/linux/i ) {
            $config{link_libraries} .= " -lpthread";
            next;
        }
        $config{link_libraries} .= " $_";
    }

    my %dlls = %{$self->wx_config( 'dlls' )};
    $config{_libraries} = {};

    while( my( $k, $v ) = each %dlls ) {
        if( @paths ) {
            my $found = 0;
            foreach my $path ( @paths ) {
                $found = 1 if -f File::Spec->catfile( $path, $v->{dll} );
            }
            warn "'$k' library not found" and next unless $found;
        }

        $config{_libraries}{$k} = $v;
    }

    return %config;
}

sub _call_wx_config {
    My::Build::Any_wx_config::_init;

    my $self = shift;
    my $options = join ' ', map { "--$_" } @_;
    my $wx_config = $ENV{WX_CONFIG} || 'wx-config';

    # not completely correct, but close
    $options = "--static $options" if $self->awx_static;

    my $t = qx($wx_config $options);
    chomp $t;

    return $t;
}

sub awx_compiler_kind {
    My::Build::Any_wx_config::_init;

    return Alien::wxWidgets::Utility::awx_compiler_kind( $_[1] )
}

1;
