package My::Build::Win32;

use strict;
use base qw(My::Build::Base);
use My::Build::Utility qw(awx_arch_file awx_install_arch_file);
use Config;
use Fatal qw(open close);

my $initialized;

sub _init {
    return if $initialized;
    $initialized = 1;

    # check for WXDIR and WXWIN environment variables
    unless( exists $ENV{WXDIR} or exists $ENV{WXWIN} ) {
        warn <<EOT;

**********************************************************************
WARNING!

You need to set the WXDIR or WXWIN variables; refer to
docs/install.txt for a detailed explanation
**********************************************************************

EOT
        exit 1;
    }

    $ENV{WXDIR} = $ENV{WXWIN} unless exists $ENV{WXDIR};
    $ENV{WXWIN} = $ENV{WXDIR} unless exists $ENV{WXWIN};
}

sub awx_grep_dlls {
    my( $self, $libdir, $digits ) = @_;
    my $ret = {};
    my $suff = ( $self->awx_unicode ? 'u' : '' ) .
               ( $self->awx_debug ? 'd' : '' );

    my @dlls = grep { m/${digits}\d*${suff}_/ }
               glob( File::Spec->catfile( $libdir, '*.dll' ) );
    my @libs = grep { m/(?:lib)?wx(?:msw|base)[\w\.]+$/ }
               grep { m/${digits}\d*${suff}(_|\.)/ }
               glob( File::Spec->catfile( $libdir, "*$Config{lib_ext}" ) );

    foreach my $full ( @dlls, @libs ) {
        my( $name, $type );
        local $_ = File::Basename::basename( $full );
        m/^[^_]+_([^_\.]+)/ and $name = $1;
        $name = 'base' if !defined $name || $name =~ m/^(gcc|vc)$/;
        $type = m/$Config{lib_ext}$/i ? 'lib' : 'dll';
        $ret->{$name}{$type} = $full;
    }

    die "Configuration error: could not find libraries for this configuration"
      unless exists $ret->{core}{dll} and exists $ret->{core}{lib};

    return $ret;
}

sub awx_wx_config_data {
    my $self = shift;

    return {};
}

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

    $config{config}{toolkit} = 'msw';
    $config{shared_library_path} = awx_install_arch_file( "rEpLaCe/lib" );

    die "Unable to find setup.h directory"
      unless $self->wx_config( 'cxxflags' )
                 =~ m{[/-]I(\S+lib[\\/][\w\\/]+)(?:\s|$)};
    $self->{awx_setup_dir} = $1;

    $self->{awx_data}{version} = $self->awx_w32_bakefile_version
      if -f $self->awx_w32_build_cfg;

    return %config;
}

sub awx_w32_bakefile_version {
    my $self = shift;
    my $build_cfg = $self->awx_w32_build_cfg;
    my $in;

    open $in, $build_cfg;
    my %ver = map { split /=/ } grep /^WXVER_/, map { s/\s//g; $_ } <$in>;
    close $in;

    return join '.', @ver{qw(WXVER_MAJOR WXVER_MINOR WXVER_RELEASE)};
}

sub awx_w32_build_cfg {
    my $self = shift;
    File::Spec->catfile( $self->{awx_setup_dir}, 'build.cfg' )
}

sub files_to_install {
    my $self = shift;
    my $dlls = $self->awx_wx_config_data->{dlls};

    my $setup_h = File::Spec->catfile( $self->{awx_setup_dir},
                                       'wx', 'setup.h' );
    my $build_cfg = $self->awx_w32_build_cfg;
    my %files;

    $files{$build_cfg} = awx_arch_file( "rEpLaCe/lib/build.cfg" )
      if -f $build_cfg;

    $files{$setup_h} = awx_arch_file( "rEpLaCe/lib/wx/setup.h" );
    foreach my $dll ( map { $_->{dll} } values %$dlls ) {
        next unless defined $dll;
        my $base = File::Basename::basename( $dll );
        $files{$dll} = awx_arch_file( "rEpLaCe/lib/$base" );
    }
    foreach my $lib ( map { $_->{lib} } values %$dlls ) {
        next unless defined $lib;
        my $base = File::Basename::basename( $lib );
        $files{$lib} = awx_arch_file( "rEpLaCe/lib/$base" );
    }

    return %files;
}

sub build_wxwidgets {
    my $self = shift;
    my %files = $self->files_to_install;

    while( my( $from, $to ) = each %files ) {
        $to =~ s/rEpLaCe/$self->{awx_base}/g;
        $self->copy_if_modified( from => $from, to => $to );
    }
}

sub awx_get_package {
    My::Build::Win32::_init();

    my $package;

    SWITCH: {
        local $_ = $Config{cc};

        /^cl/i  and $package = 'Win32_MSVC'  and last SWITCH;
        /^gcc/i and $package = 'Win32_MinGW' and last SWITCH;

        # default
        die "Your compiler is not currently supported on Win32"
    };

    my $mak_env_in = File::Spec->catfile( $ENV{WXDIR}, 'src', 'make.env.in' );

    return -f $mak_env_in ? $package . '_Tmake' : $package . '_Bakefile';
}

# MSLU is default when using Unicode *and* it has not
# been explicitly disabled
sub awx_mslu {
    return $_[0]->args( 'mslu' ) if defined $_[0]->args( 'mslu' );
    return $_[0]->awx_unicode;
}

1;
