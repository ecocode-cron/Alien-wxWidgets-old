package My::Build::Any_wx_config_Tmake;

use strict;
our @ISA = qw(My::Build::Any_wx_config::Base);

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data;

    foreach my $item ( qw(cxx ld cxxflags version libs basename prefix) ) {
        $data{$item} = $self->_call_wx_config( $item );
    }
    $data{ld} =~ s/\-o\s*$/ /; # wxWidgets puts 'ld -o' into LD
    $data{libs} =~ s/\-lwx\S+//g;
    ( my $ver = $data{version} ) =~ s/\.\d+$//;

    my $lib_link = sub {
        $_[0] eq 'core' ?
          '-l' . $data{basename} . '-' . $ver :
          '-l' . $data{basename}  . '_' . $_[0] . '-' . $ver;
    };
    my $lib_dll = sub {
        'lib' . substr( $lib_link->( $_[0] ), 2 ) . '.' . $self->awx_dlext;
    };

    $data{dlls} = { core => { dll  => $lib_dll->( 'core' ),
                              link => $lib_link->( 'core' ) },
                    stc  => { dll  => $lib_dll->( 'stc' ),
                              link => $lib_link->( 'stc' ) },
                    xrc  => { dll  => $lib_dll->( 'xrc' ),
                              link => $lib_link->( 'xrc' ) },
                    gl   => { dll  => $lib_dll->( 'gl' ),
                              link => $self->_call_wx_config( 'gl-libs' ) },
                   };
    delete $data{dlls}{gl} unless $data{dlls}{gl}{link};

    $self->{awx_data} = \%data;
}

sub awx_uses_bakefile { 0 }
sub awx_is_monolithic { 0 }

1;
