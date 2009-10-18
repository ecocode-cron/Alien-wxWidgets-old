package My::Build::MacOSX_wx_config;

use strict;
use base qw(My::Build::Any_wx_config);

use Config;

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

    $data{cxx} =~ s{-isysroot\s+\S+}{}g;
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

sub build_wxwidgets {
    my( $self ) = @_;

    # can't build wxWidgets 2.8.x with 64 bit Perl
    if(    $Config{ptrsize} == 8
        && $self->notes( 'build_data' )->{data}{version} =~ /^2.8/ ) {
        print <<EOT;
=======================================================================
The 2.8.x wxWidgets for OS X does not support 64-bit. In order to build
wxPerl you will need to either recompile Perl as a 32-bit binary or (if
using the Apple-provided Perl) force it to run in 32-bit mode (see "man
perl").  Alpha 64-bit wx for OS X is in 2.9.x, but untested in wxPerl.
=======================================================================
EOT
        exit 1;
    }

    $self->SUPER::build_wxwidgets;
}

1;
