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

    $data{dlls} = { core => { link => $lib_link->( 'core' ) },
                    stc  => { link => $lib_link->( 'stc' ) },
                    xrc  => { link => $lib_link->( 'xrc' ) },
                    gl   => { link => $self->_call_wx_config( 'gl-libs' ) },
                   };

    $self->{data} = \%data;
}

sub awx_uses_bakefile { 0 }
sub awx_is_monolithic { 0 }

1;
