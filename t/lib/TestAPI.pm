package TestAPI;
use Moose;
use MooseX::Net::API;

net_api_declare fake_api => (
    base_url               => 'http://localhost/root',
    format                 => 'json',
    format_mode            => 'content-type',
    require_authentication => 0,
);

net_api_method foo => (
    description => 'this does foo',
    method      => 'GET',
    path        => '/foo/',
);

1;

