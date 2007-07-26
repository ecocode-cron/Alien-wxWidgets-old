package My::Build::Utility;

use strict;
use base qw(Exporter);
use Config;
use Fatal qw(open);

our @EXPORT_OK = qw(awx_arch_file awx_install_arch_file
                    awx_install_arch_auto_file
                    awx_arch_dir awx_install_arch_dir awx_touch);

sub awx_arch_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( 'blib', 'arch', 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

sub awx_arch_dir {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catdir( 'blib', 'arch', 'Alien', 'wxWidgets',
                        File::Spec->splitdir( $dir ), $file );
}

sub awx_install_arch_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( $Config{sitearchexp}, 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

sub awx_install_arch_dir {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catdir( $Config{sitearchexp}, 'Alien', 'wxWidgets',
                        File::Spec->splitdir( $dir ), $file );
}

sub awx_install_arch_auto_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( $Config{sitearchexp}, 'auto', 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

sub awx_touch {
    require ExtUtils::Command;
    local @ARGV = @_;
    ExtUtils::Command::touch();
}

1;
