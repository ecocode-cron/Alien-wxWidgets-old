#!/usr/bin/perl -w

use strict;
use lib 'inc';
use My::Build;

My::Build->new
  ( module_name     => 'Alien::wxWidgets',
    license         => 'perl',
    author          => 'Mattia Barbon <mbarbon@cpan.org>',
    requires        => { 'File::Spec'    => '0.80',
                         'Module::Build' => '0.26',
                        },
    get_options     => { debug      => { type => '!' },
                         unicode    => { type => '!' },
                         mslu       => { type => '!' },
                         static     => { type => '!' },
                        },
  )->create_build_script;
