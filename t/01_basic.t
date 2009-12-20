use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib ('t/lib');
use FakeAPI;

my $obj = FakeAPI->new;
ok $obj, "... object created";
ok $obj->meta->has_attribute('api_useragent'),
    "... useragent attribute have been added";

ok my $method = $obj->meta->find_method_by_name('get_user'),
    '... method get_user have been created';

ok $method->meta->has_attribute('path'), '... method bar have attribute path';
is $method->path, '/user/$id', '... get good path value';

ok my @methods = $obj->meta->local_api_methods(), '... get api methods';
is scalar @methods, 6, '... get 6 methods in our API';

ok my $users = $obj->users(), "... get users list";
is $users->[0]->{user}, "bruce wayne", "... get bruce wayne";

ok my $user = $obj->get_user( id => $users->[0]->{id} ),
    "... fetch bruce wayne informations";
is $user->{user}, "bruce wayne", "... get bruce wayne";

dies_ok { $obj->get_user( id => 12 ) } "... can't fetch unknown user";
my $err = $@;
is $err->http_code, 404, "... get 404";

my $auth_obj = FakeAPI->new();
my $res = $auth_obj->auth_get_user(id => 1);

done_testing;
