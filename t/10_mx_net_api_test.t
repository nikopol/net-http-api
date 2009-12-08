use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'requires Catalyst::Action::REST'
        unless eval { require Catalyst::Action::REST };
}

{

    package catalysttestapi;
    use Moose;
    use MooseX::Net::API::Test;

    test_api_declare 'TestAPI' => (
        catalyst          => 1,
        catalyst_app_name => 'TestApp'
    );

    test_api_method foo => (
        tests => {
            simple => [
                {
                    # pouvoir surcharger
                    test     => 'is_deeply',
                    expected => { status => 1 }
                },
                'ok',
            ]
        }
    );
}

#content_like    => [ { expected => qr/status: 1/ }, ],
#action_ok       => [],
#action_redirect => [],
#action_notfound => [],
#contenttype_is  => [],

catalysttestapi->run();

done_testing;
