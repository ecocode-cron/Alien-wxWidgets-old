package My::Build::Any_wx_config_Bakefile;

use strict;
our @ISA = qw(My::Build::Any_wx_config::Base);

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data;

    foreach my $item ( qw(cxx ld cxxflags version libs) ) {
        $data{$item} = $self->_call_wx_config( $item );
    }
    $data{ld} =~ s/\-o\s*$/ /; # wxWidgets puts 'ld -o' into LD

#    if( $data{version} !~ m/^2\.[56]/ ) {
#        $data{ldflags} = $self->_call_wx_config( 'ldflags' );
#    }

    $data{libs} =~ s/\-lwx\S+//g;

    $self->{data} = \%data;
}



1;
