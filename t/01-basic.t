use Plack::Test;
use Test::More;
use Plack::Middleware::Proxy::ByHeader;
use HTTP::Request::Common;
use Plack::Builder;
use URI;

eval {
    builder { enable "Proxy::ByHeader", header => 'X-Taz-Proxy-To' };
};
chomp( my $err = $@ );
$err =~ s/ at .*//;
is( $err, q{argument to 'header' must be an array reference} );

eval {
    builder { enable "Proxy::ByHeader", allowed => 'www.taz.de' };
};
chomp( my $err = $@ );
$err =~ s/ at .*//;
is( $err, q{argument to 'allowed' must be an array reference} );

test_psgi(
    app => builder {
        enable "Proxy::ByHeader",
          header => [ 'X-Taz-Proxy-To', 'Host' ],
          allowed => [ 'example.com', 'www.example.com', 'www2.example.com' ];

        sub {
            my ($env) = shift;
            my $url = URI->new( $env->{'plack.proxy.url'} );
            is( $url, "http://www.example.com/foo" );
            return [ 200, [], ["Hello"] ];
          }
    },
    client => sub {
        my $cb  = shift;
        my $res = $cb->(
            GET "/foo",
            Host             => 'example.com',
            'X-Taz-Proxy-To' => 'www.example.com'
        );
    }
);

done_testing();
