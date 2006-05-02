package My::Build::Win32_MinGW;

use strict;
use base qw(My::Build::Win32);
use My::Build::Utility qw(awx_arch_file awx_install_arch_file
                          awx_install_arch_dir awx_arch_dir);
use Config;

sub _find_make {
    my( @try ) = qw(mingw32-make make);

    foreach my $name ( @try ) {
        foreach my $dir ( File::Spec->path ) {
            my $abs = File::Spec->catfile( $dir, "$name.exe" );
            return $name if -x $abs;
        }
    }

    return 'make';
}

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
    my $incdir = $self->awx_wx_config_data->{wxinc};
    my $cincdir = $self->awx_wx_config_data->{wxcontrinc};
    my $iincdir = awx_install_arch_dir( 'rEpLaCe/include' );

    foreach ( split /\s+/, $cccflags ) {
        m(^-DSTRICT) && next;
        m(^\.d$) && next; # broken makefile
        m(^-W.*) && next; # under Win32 -Wall gives you TONS of warnings
        m(^-I) && do {
            next if m{(?:regex|zlib|jpeg|png|tiff)$};
            if( $self->notes( 'build_wx' ) ) {
                $_ =~ s{\Q$cincdir\E}{$iincdir};
                $_ =~ s{\Q$incdir\E}{$iincdir};
            }
            if( $_ =~ /-I\Q$self->{awx_setup_dir}\E/ ) {
                $config{include_path} .=
                  '-I' . awx_install_arch_file( 'rEpLaCe/lib' ) . ' ';
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
        if( $value->{link} ) {
            $config{_libraries}{$key}{link} = $value->{link};
        } elsif( $value->{lib} ) {
            my $lib = $config{_libraries}{$key}{lib};
            $lib =~ s/^lib(.*?)(?:\.dll)?\.a$/$1/;
            $config{_libraries}{$key}{link} = '-l' . $lib;
        }
    }

    return %config;
}

sub awx_compiler_kind { 'gcc' }

sub files_to_install {
    my $self = shift;
    my $dll = 'mingwm10.dll';
    my $dll_from = $self->awx_path_search( $dll );

    return ( $self->SUPER::files_to_install(),
             ( $dll_from => awx_arch_file( "rEpLaCe/lib/$dll" ) ) );
}

sub awx_strip_dlls {
    my( $self ) = @_;
    my( $dir ) = grep !/Config/, glob( awx_arch_dir( '*' ) );

    $self->_system( "attrib -r $dir\\lib\\*.dll" );
    $self->_system( "strip $dir\\lib\\*.dll" );
    $self->_system( "attrib +r $dir\\lib\\*.dll" );
}

1;
