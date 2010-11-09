# Net::HTTP::API

## SYNOPSIS

    package My::Net::API;
    use Net::HTTP::API;

    # we declare the API meta:
    # - api_base_url   : url that will be our base
    # - api_format     : what's the format for this API
    # - api_format_mode: how do we set the format

    net_api_declare twitter => (
        api_base_url    => 'http://search.twitter.com/',
        api_format      => 'json',
        api_format_mode => 'append',
    );

    # we declare one method now:
    # - method  : HTTP method
    # - path    : path for the request
    # - params  : list of params accepted for this request
    # - required: list of required params

    net_api_method search => (
        method   => 'GET',
        path     => '/search',
        params   => [qw/q lang local page/],
        required => [qw/q/],
    );

    1;

    my $api = My::Net::API->new();
    my $res = $api->search(q => 'Perl');

## head1 DESCRIPTION

Net::HTTP::API is a module to help to easily create a client for a web API.

**THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE**
