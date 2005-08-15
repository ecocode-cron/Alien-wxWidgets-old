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
    get_options     => { debug      => { default => 0 },
                         unicode    => { default => 0 },
                         mslu       => { default => 1 },
                         static     => { default => 0 },
                        },
  )->create_build_script;
