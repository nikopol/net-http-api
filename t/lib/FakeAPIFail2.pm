package FakeAPI;
use Moose;
use MooseX::Net::API;

net_api_declare fake_api => (
    base_url               => 'http://identi.ca/api',
    format                 => 'json',
    format_mode            => 'content-type',
    require_authentication => 0,
);

net_api_method baz => (
    description => 'this one does baztwo',
    method      => 'BAZ',
    path        => '/baz/',
    params      => [qw/foo/],
    required    => [qw/bla/],
);

sub get_foo { return 1; }

1;
