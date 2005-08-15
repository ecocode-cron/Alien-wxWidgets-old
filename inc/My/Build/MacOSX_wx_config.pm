package My::Build::MacOSX_wx_config;

use strict;
use base qw(My::Build::Any_wx_config);

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};
    my %data = %{$self->SUPER::awx_wx_config_data};

    # MakeMaker does not like the "-framework foo" options
    $data{libs} =~ s/-framework\s+\w+//g;

    $data{ld} = $data{cxx};
    $data{cxxflags} .= ' -UWX_PRECOMP ';

    $self->{awx_data} = \%data;
}

1;
