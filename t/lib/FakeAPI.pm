package FakeAPI;
use Moose;
use MooseX::Net::API;
use LWP::UserAgent;
use HTTP::Response;
use JSON::XS;

net_api_declare demorest => (
    base_url => "http://example.com/",
    format         => 'json',
    format_mode    => 'content-type',
    authentication => 0,
    username       => 'foo',
    password       => 'bar',
    useragent      => sub {
        my ($self) = @_;
        my $ua = LWP::UserAgent->new();
        $ua->add_handler(
            request_send => sub {
                my $request = shift;
                my $res = HTTP::Response->new(200, 'OK');
                $res->header('content-type' => 'application/json');
                $res->content(encode_json {status => 1});
                return $res;
            }
        );
        return $ua;
    },
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
    description =>
        'fetch information about a specific user with authentication',
    method         => 'GET',
    path           => '/auth_user/$id',
    params         => [qw/id/],
    required       => [qw/id/],
    expected       => [qw/200 404/],
    authentication => 1,
);

1;
