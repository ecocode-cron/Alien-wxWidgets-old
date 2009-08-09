#!/usr/bin/perl -w

BEGIN { our $NO_INIT = 1 }

use strict;
use lib "lib", "inc";
use My::Build;

our( $TYPE, $URL );

# new_from_context is broken: it does not restore
# @INC set in Build.PL before trying to load a base class not
# defined using ->subclass...
my $class = Module::Build->subclass
  ( class            => 'My::Build::new_from_context_is_broken',
    code             => <<'EOC' );
use lib qw(lib inc);
@ISA = qw(My::Build Module::Build);
require My::Build;
EOC
my $build = $class->new
  ( module_name     => 'Alien::wxWidgets',
    license         => 'perl',
    author          => 'Mattia Barbon <mbarbon@cpan.org>',
    requires        => { perl                             => '5.006',
                         'Module::Pluggable'              => '2.6',
                        },
    build_requires  => { 'Module::Build'                  => '0.28',
                         'ExtUtils::CBuilder'             => '0.24',
                         },
    configure_requires => { 'Module::Build'               => '0.28',
                            },
    get_options     => { 'wxWidgets-debug'         => { type => '!' },
                         'wxWidgets-unicode'       => { type => '!' },
                         'wxWidgets-mslu'          => { type => '!' },
                         'wxWidgets-static'        => { type => '!' },
                         'wxWidgets-monolithic'    => { type => '!' },
                         'wxWidgets-universal'     => { type => '!' },
                         'wxWidgets-build'         => { type => '!' },
                         'wxWidgets-portable'      => { type => '!' },
                         'wxWidgets-build-opengl'  => { type => '!' },
                         'wxWidgets-source'        => { type => '=s' },
                         },
    create_makefile_pl => 'passthrough',
  );

my $accept_defaults = $ENV{PERL5_CPANPLUS_IS_RUNNING}
                   || $ENV{CPAN_SHELL_LEVEL}; 
my $build_wx_dflt = 'yes';
my $build_wx_opengl_dflt = 'yes';
my $build_prompt = 'Do you want to fetch and build wxWidgets from sources?';
if( $^O eq 'MSWin32' && ( $ENV{WXWIN} || $ENV{WXDIR} ) ) {
    $build_wx_dflt = 'no';
    $build_prompt = sprintf <<EOP, ( $ENV{WXWIN} || $ENV{WXDIR} );
A wxWidgets build seems to be in '%s', so it should be safe to answer
'no' to the following question

$build_prompt
EOP
} else {
    require My::Build::Base;
    my $wx_config = My::Build::Base->awx_path_search( 'wx-config' );
    if( $wx_config ) {
        my $ans = `wx-config --version`;
        if( $ans =~ /^2\./ ) {
            my $prefix = `wx-config --prefix`;
            chomp foreach $ans, $prefix;
            $build_wx_dflt = 'no' ;
            $build_prompt = sprintf <<EOP, $ans, $prefix;
wxWidgets %s seems to be installed in '%s', so it should be safe to
answer 'no' to the following question:

$build_prompt
EOP
        }
    }
}
if( $^O ne 'darwin' && $^O ne 'MSWin32' ) {
    $build_wx_opengl_dflt = 'no';
}
if( $ENV{AWX_URL} ) {
    $build_wx_dflt = 'yes';
}
if( $ENV{AUTOMATED_TESTING} ) {
    if( $^O ne 'darwin' && $^O ne 'MSWin32' ) {
        my $pkg_config = $ENV{PKG_CONFIG} || 'pkg-config';
        my $ans = `$pkg_config --modversion gtk+-2.0 2>&1`;
        unless( $ans =~ /^2\./ ) {
            print <<EOT;
Could not detect GTK+ 2 by running '$pkg_config': aborting

== pkg-config output: ====================================
$ans==========================================================
EOT
            exit 0;
        }
    }
}
chomp $build_prompt;
my $build_wx = _askyn( $build, 'wxWidgets-build',
                       $build_prompt, $build_wx_dflt );
$build->notes( 'build_wx' => $build_wx );
$build->notes( 'mk_portable' => $build->args('wxWidgets-portable') );
if( $build_wx ) {
    $TYPE = _ask( $build, 'wxWidgets-source', 'Which archive type?', 'tar.gz' );
    $URL = $ENV{AWX_URL};
    $build->notes( 'build_data' => do 'patches/data' );
}
if( $build_wx ) {
    my $build_wx_unicode = _askyn( $build, 'wxWidgets-unicode',
                                   'Do you want to enable Unicode support',
                                   'yes' );
    $build->notes( 'build_wx_unicode' => $build_wx_unicode );
}
if( $build_wx ) {
    my $build_wx_opengl = _askyn( $build, 'wxWidgets-build-opengl',
                                  'Do you want to include OpenGL support',
                                  $build_wx_opengl_dflt );
    $build->notes( 'build_wx_opengl' => $build_wx_opengl );
}

$build->create_build_script;

sub _askyn {
    my( $build, $arg, $question, $default ) = @_;
    my $res =
      defined $build->args( $arg ) ? $build->args( $arg ) :
      exists $ENV{"AWX_\U$arg"}    ? $ENV{"AWX_\U$arg"} :
      $accept_defaults             ? $default :
                                     $build->y_n( $question, $default );

    return $res
}

sub _ask {
    my( $build, $arg, $question, $default ) = @_;
    my $res =
      defined $build->args( $arg ) ? $build->args( $arg ) :
      exists $ENV{"AWX_\U$arg"}    ? $ENV{"AWX_\U$arg"} :
      $accept_defaults             ? $default :
                                     $build->prompt( $question, $default );

    return $res
}
