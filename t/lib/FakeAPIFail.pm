package FakeAPI;
use Moose;
use MooseX::Net::API;

net_api_declare fake_api => (
    base_url               => 'http://identi.ca/api',
    format                 => 'json',
    format_mode            => 'content-type',
    require_authentication => 0,
);

net_api_method foo => (
    description => 'this does foo',
    method      => 'GET',
    path        => '/foo/',
    required    => [qw/bar/],
);

1;
