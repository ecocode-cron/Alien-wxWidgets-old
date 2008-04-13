package My::Build::MacOSX_wx_config;

use strict;
use base qw(My::Build::Any_wx_config);

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};
    my %data = ( linkflags => '', %{$self->SUPER::awx_wx_config_data} );

    # MakeMaker does not like some options
    $data{libs} =~ s{-framework\s+\w+}{}g;
    $data{libs} =~ s{-isysroot\s+\S+}{}g;
    $data{libs} =~ s{-L/usr/local/lib\s}{}g;

    $data{libs} =~ s{\s(-arch\s+\w+)}
                    {$data{linkflags} .= " $1 ";
                     $data{cxxflags} .= " $1 ";
                     ' '}eg;

    $data{ld} = $data{cxx};
    $data{cxxflags} .= ' -UWX_PRECOMP ';

    $self->{awx_data} = \%data;
}

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

    $config{link_flags} .= $self->wx_config( 'linkflags' );

    return %config;
}

sub awx_build_toolkit { 'mac' }
sub awx_dlext { 'dylib' }

1;
