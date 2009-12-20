use inc::Module::Install;
name 'MooseX-Net-API';
all_from 'lib/MooseX/Net/API.pm';

requires 'Moose';
requires 'Try::Tiny';
requires 'URI';
requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'MooseX::Types::Moose';
requires 'JSON::XS';
requires 'YAML::Syck';
requires 'XML::Simple';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Exception';
use_test_base;
auto_include;
WriteAll;
