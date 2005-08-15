package My::Build::Win32_MinGW;

use strict;
use base qw(My::Build::Win32);
use My::Build::Utility qw(awx_install_arch_file);
use Config;

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

    $config{c_flags} .= " -fvtable-thunks ";

    if( $self->awx_debug ) {
        $config{c_flags} .= ' -g ';
    } else {
        $config{link_flags} .= ' -s ';
    }

    my $cccflags = $self->wx_config( 'cxxflags' );
    my $libs = $self->wx_config( 'libs' );

    foreach ( split /\s+/, $cccflags ) {
        m(^-DSTRICT) && next;
        m(^\.d$) && next; # broken makefile
        m(^-W.*) && next; # under Win32 -Wall gives you TONS of warnings
        m(^-I) && do {
            next if m{(?:regex|zlib|jpeg|png|tiff)$};
            if( $_ =~ /-I\Q$self->{awx_setup_dir}\E/ ) {
                $config{include_path} .=
                  '-I' . awx_install_arch_file( 'lib' ) . ' ';
            } else {
                $config{include_path} .= "$_ ";
            }
            next;
        };
        m(^-D) && do { $config{defines} .= "$_ "; next; };
        $config{c_flags} .= "$_ ";
    }

    foreach ( split /\s+/, $libs ) {
        m(wx|unicows)i || next;
        next if m{(?:wx(?:zlib|regexu?|expat|png|jpeg|tiff)[ud]{0,2})$};
        $config{link_libraries} .= "$_ ";
    }

    my $dlls = $self->awx_wx_config_data->{dlls};
    $config{_libraries} = {};

    while( my( $key, $value ) = each %$dlls ) {
        $config{_libraries}{$key} =
          { map { $_ => File::Basename::basename( $value->{$_} ) }
                keys %$value };
        if( $value->{lib} ) {
            my $lib = $config{_libraries}{$key}{lib};
            $lib =~ s/^lib(.*?)(?:\.dll)?\.a$/$1/;
            $config{_libraries}{$key}{link} = '-l' . $lib;
        }
    }

    return %config;
}

1;
