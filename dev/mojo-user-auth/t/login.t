#!perl

package MyTest::Mech::LibXML;

use Test::WWW::Mechanize::Mojo '0.0.3';
use base 'Test::WWW::Mechanize::Mojo';

use HTML::TreeBuilder::LibXML;

use Test::More;

sub contains_tag
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $tag_spec = shift;
    my $blurb = shift;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($mech->content());
    $tree->eof();

    my $ret = $tree->look_down(@$tag_spec);

    ok($ret, $blurb);

    return $ret;
}

sub tree_matches_xpath
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $xpath = shift;
    my $blurb = shift;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($mech->content());
    $tree->eof();

    my @nodes = $tree->findnodes($xpath);
    return ok(scalar(@nodes), $blurb);
}

package MyTest::Mech;

our @ISA = (qw(MyTest::Mech::LibXML));

sub not_logged_in
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $blurb = shift;

    return $mech->tree_matches_xpath(
        q{//div[@id='status']//b[contains(text(), 'Not logged in')]},
        $blurb,
    );
}

sub logged_in_as
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $email = shift;
    my $blurb = shift;

    return $mech->tree_matches_xpath(
        qq{//div[\@id='status']//b[contains(text(), 'Logged in as ${email}')]},
        $blurb,
    );
}

package main;

use strict;
use warnings;

BEGIN
{
    # Reset the database.
    unlink("insurgent-auth.sqlite");
}

use Test::More tests => 32;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../user-auth.pl";

my $t = Test::Mojo->new;
my $mech = MyTest::Mech->new(tester => $t);

# TEST
$mech->get_ok("/", "Got the page ok.");

# TEST
is ($mech->status(), 200, "Status is 200 for Root");

# TEST
$mech->not_logged_in("Status says not logged in.");

# TEST
$t->content_like(qr{
    <li><a\ href="[^"]*\blogin/?">Login\ to\ an\ existing\ account</a></li>\s+
    <li><a\ href="[^"]*\bregister/?">Register\ a\ new\ account</a></li>
    }x);

# TEST
$mech->follow_link_ok({text => "Register a new account"}, 
    "Was able to follow the link to register."
);

# TEST
$mech->has_tag("h1", "Register an account", "Has an appropriate <h1> tag.");

my $email = 'sophie@myhome.tld';
my $password = "Sophie-Iz-De-Ossum";

# TEST
$mech->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
            password => $password,
            password2 => "Something else",
            fullname => "Sophie Esmeralda Johnson",
        },
    },
    "Submit form with different passwords.",
);

# TEST
$mech->has_tag("h1", "Registration failed - passwords don't match.");


# TEST
$mech->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
            password => $password,
            password2 => "Something else",
            fullname => "Sophie Esmeralda Johnson",
        },
    },
    "Submit the new form on the rejection screen with different passwords.",
);

# TEST
$mech->has_tag("h1", "Registration failed - passwords don't match.");

my $short_pass = "heh";

# TEST
$mech->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
            password => $short_pass,
            password2 => $short_pass,
            fullname => "Sophie Esmeralda Johnson",
        },
    },
    "Submit the new form on the rejection screen with different passwords.",
);

# TEST
$mech->not_logged_in("Status says not logged #2 .");

# TEST
$mech->has_tag("h1", "Registration failed - password is too short.");

# TEST
$mech->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
            password => $password,
            password2 => $password,
            fullname => "Sophie Esmeralda Johnson",
        },
    },
    "Submit the form - should succeed now.",
);

# TEST
$mech->not_logged_in("Status says not logged #2 .");

# TODO : test that the user was registered properly.

# TEST
$mech->get_ok("/", "Got the front page again.");

# TEST
$mech->follow_link_ok({text => "Register a new account"}, 
    "Was able to follow the link to register (2nd time)."
);

my $pass2 = "FooBarasdmk--34t+536'Y";
# TEST
$mech->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
            password => $pass2,,
            password2 => $pass2,
            fullname => "Sophie Goringa Lactor",
        },
    },
    "Submit form with existing E-mail.",
);

# TEST
$mech->has_tag("h1", "Registration failed - the email was already registered");


# TEST
$mech->get_ok("/", "Got the front page.");

# TEST
$mech->follow_link_ok({text => "Login to an existing account"},
    "Was able to follow the login link."
);

# TEST
$mech->has_tag("h1", "Login form", 
    "Login page has an appropriate <h1> tag"
);

# TEST
$mech->submit_form_ok(
    {
        form_id => "login",
        fields =>
        {
            email => $email,
            password => "This-is-not-a-Password",
        },
    },
    "Submit form with the wrong password",
);

# TEST
$mech->has_tag("h1", "Wrong Login or Incorrect Password", 
    "Could not login with incorrect password"
);

# TEST
$mech->submit_form_ok(
    {
        form_id => "login",
        fields =>
        {
            email => $email,
            password => $password,
        },
    },
    "Submit login form with the right password",
);

# TEST
$mech->has_tag("h1", "Login successful", "Login was successful (<h1>)");

# TEST
$mech->logged_in_as($email, "Now status shows logged in.");

# TEST
$mech->get_ok("/", "Got the front page.");

# TEST
$mech->logged_in_as($email, "Status shows logged in in the front page.");

# TEST
$mech->follow_link_ok({text => "Logout",},
    "Was able to follow the logout link."
);

# TEST
$mech->has_tag("h1", "You are now logged-out",
    "Logged-out h1",
);

# TEST
$mech->not_logged_in("Status says not logged in after logout.");
