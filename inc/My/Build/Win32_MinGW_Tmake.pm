package My::Build::Win32_MinGW_Tmake;

use strict;
use base qw(My::Build::Win32_MinGW);

use Config;
use File::Spec;
use File::Basename ();
use My::Build::Utility qw(awx_install_arch_file);

my $makefile = File::Spec->catfile
      ( File::Basename::dirname( $INC{'My/Build/Win32.pm'} ), 'gmake.mak' );

sub _call_make {
    my $self = shift;
    my $final = $self->awx_debug ? 'FINAL=0' : 'FINAL=1';
    my $unicode = $self->awx_unicode ? 'UNICODE=1' : 'UNICODE=0';
    my $make = $self->_find_make;
    $unicode .= ' EXTRALIBS=-lunicows' if $self->awx_mslu;
    my $t = qx($make -s -f $makefile @_ $final $unicode CXXFLAGS=-Os);
    chomp $t;
    $t =~ s{[/-]([ID])}{-$1}g;

    return $t;
}

sub awx_wx_config_data {
    My::Build::Win32::_init();

    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data = ( %{$self->SUPER::awx_wx_config_data},
                 'cxx'     => 'g++',
                 'ld'      => 'g++',
               );

    foreach my $item ( qw(cxxflags version libs) ) {
        $data{$item} = $self->_call_make( $item );
    }

    my $implib = $self->_call_make( 'implib' );
    my $dll = $implib;
    $dll =~ s/$Config{_a}$/.dll/; $dll =~ s{([\\/])lib([^\\/]+)$}{$1$2};

    my $lib_name = sub {
        $ENV{WXDIR} . '\\lib\\' .
          'lib' . $_[0] . $Config{_a};
    };

    my $lib_link = sub {
        awx_install_arch_file( $self, 'rEpLaCe/lib/' . 'lib' . $_[0] . $Config{_a} );
    };
    my $link_implib = awx_install_arch_file
      ( $self, 'rEpLaCe/lib/' . File::Basename::basename( $implib ) );

    $data{dlls} = { core => { dll  => $dll,
                              lib  => $implib,
                              link => $link_implib },
                    stc  => { lib  => $lib_name->( 'stc' ),
                              link => $lib_link->( 'stc' ) },
                    xrc  => { lib  => $lib_name->( 'wxxrc' ),
                              link => $lib_link->( 'wxxrc' ) },
                   };

    $self->{awx_data} = \%data;
}

sub awx_uses_bakefile { 0 }

1;
