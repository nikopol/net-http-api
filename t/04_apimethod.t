use strict;
use warnings;
use Test::More;
use Test::Exception;
use MooseX::Net::API::Meta::Method;

dies_ok {
    MooseX::Net::API::Meta::Method->wrap(
        name         => 'test_method',
        package_name => 'test::api',
        body         => sub {1},
    );
}
"missing some params";

ok my $method = MooseX::Net::API::Meta::Method->wrap(
    name         => 'test_method',
    package_name => 'test::api',
    body         => sub {1},
    method       => 'GET',
    path         => '/user/',
  ),
  'method created';

is $method->method, 'GET', 'method is GET';

ok $method = MooseX::Net::API::Meta::Method->wrap(
    name         => 'test_method',
    package_name => 'test::api',
    method       => 'GET',
    path         => '/user/',
    params       => [qw/name id street/],
    required     => [qw/name id/],
);

done_testing;
