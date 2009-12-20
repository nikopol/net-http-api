package FakeAPI;
use Moose;
use MooseX::Net::API;

net_api_declare demorest => (
    base_url       => 'http://lumberjaph.net/demorest/rest',
    format         => 'json',
    format_mode    => 'content-type',
    authentication => 0,
    username       => 'foo',
    password       => 'bar',
);

net_api_method users => (
    description => 'get a list of users',
    method      => 'GET',
    path        => '/users/',
    expected    => [qw/200/],
);

net_api_method get_user => (
    description => 'fetch information about a specific user',
    method      => 'GET',
    path        => '/user/$id',
    params      => [qw/id/],
    required    => [qw/id/],
    expected    => [qw/200 404/],
);

net_api_method create_user => (
    description => 'create a new user',
    method      => 'POST',
    path        => '/user/',
    params      => [qw/user nickname/],
    required    => [qw/user nickname/],
);

net_api_method update_user => (
    description => 'update information about a specific user',
    method      => 'PUT',
    path        => '/user/$id',
    params      => [qw/id nickname/],
    required    => [qw/id nickname/],
);

net_api_method delete_user => (
    description => 'terminate an user',
    method      => 'DELETE',
    path        => '/user/$id',
    params      => [qw/id/],
    required    => [qw/id/],
);

net_api_method auth_get_user => (
    description => 'fetch information about a specific user with authentication',
    method         => 'GET',
    path           => '/auth_user/$id',
    params         => [qw/id/],
    required       => [qw/id/],
    expected       => [qw/200 404/],
    authentication => 1,
);

1;
