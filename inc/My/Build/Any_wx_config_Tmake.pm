package My::Build::Any_wx_config_Tmake;

use strict;
our @ISA = qw(My::Build::Any_wx_config::Base);

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data;
    my $basename = $self->_call_wx_config( 'basename' );

    foreach my $item ( qw(cxx ld cxxflags version libs) ) {
        $data{$item} = $self->_call_wx_config( $item );
    }
    $data{ld} =~ s/\-o\s*$/ /; # wxWidgets puts 'ld -o' into LD
    $data{libs} =~ s/\-lwx\S+//g;
    ( my $ver = $data{version} ) =~ s/\.\d+$//;

    my $lib_link = sub {
        $_[0] eq 'core' ?
          '-l' . $basename . '-' . $ver :
          '-l' . $basename  . '_' . $_[0] . '-' . $ver;
    };

    $data{dlls} = { core => { link => $lib_link->( 'core' ) },
                    stc  => { link => $lib_link->( 'stc' ) },
                    xrc  => { link => $lib_link->( 'xrc' ) },
                    gl   => { link => $self->_call_wx_config( 'gl-libs' ) },
                   };

    $self->{data} = \%data;
}

1;

