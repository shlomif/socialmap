#!/usr/bin/env perl

use strict;
use warnings;

use InsurgentSoftware::UserAuth::User;
use InsurgentSoftware::UserAuth::App;

use Mojolicious::Lite;
use MojoX::Session::Cookie;

use CGI qw();

use KiokuDB;

# Silence
app->log->level('error');

my $dir = KiokuDB->connect(
    "dbi:SQLite:dbname=./insurgent-auth.sqlite",
    create => 1,
    columns =>
    [
        email =>
        {
            data_type => "varchar",
            is_nullable => 1,
        },
    ],
);


get '/' => sub {
    my $self = shift;

    return $self->render(
        template => "index",
        layout => 'insurgent',
        title => "Main",
    );
} => "index";

get '/register/' => sub {
    my $self = shift;
    
    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->register();

} => "register";

sub register_submit
{
    my $self = shift;

    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->register_submit();
}

post '/register-submit/' => \&register_submit => "register_submit";

get '/login/' => sub {
    my $self = shift;
    
    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->login();
} => "login";

sub login_submit
{
    my $self = shift;

    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->login_submit();
}

post '/login-submit/' => \&login_submit => "login_submit";

sub logout
{
    my $self = shift;

    delete($self->session->{'login'});

    $self->render_text(
        "<h1>You are now logged-out</h1>\n",
        layout => 'insurgent',
        title => "You are now logged-out",
    );

    return;
}

get '/logout' => (\&logout) => "logout";


sub account
{
    my $self = shift;

    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->account_page();
}

get '/account' => (\&account) => "account";

sub account_change_user_info_submit
{
    my $self = shift;

    
    my $app = InsurgentSoftware::UserAuth::App->new(
        {
            mojo => $self,
            dir => $dir,
        }
    );

    return $app->change_user_info_submit();
}

post '/account/change-info' => (\&account_change_user_info_submit)
=> "change_user_info_submit";

shagadelic;

=head1 TODO

* Make sure that there are limits to the properties of a user (maximal length
of E-mail, password, etc.).

* Each page should have a more meaningful (and brief) <title> element.

=cut

__DATA__

@@ index.html.ep
% layout 'insurgent';
<h1>Insurgent Software's User Management Application</h1>

<ul>
% if ($self->session->{'login'}) {
<li><a href="<%= url_for('account') %>">Go to Your Account</a></li>
% } else {
<li><a href="<%= url_for('login') %>">Login to an existing account</a></li>
<li><a href="<%= url_for('register') %>">Register a new account</a></li>
% }
</ul>

@@ register.html.ep
% layout 'insurgent';
<h1>Register an account</h1>
<%== $register_form %>

@@ login.html.ep
% layout 'insurgent';
<h1>Login form</h1>
<%== $login_form %>

@@ account.html.ep
% layout 'insurgent';
<h1>Account page for <%= $email %></h1>

<h2 id="change_info">Change User Information</h2>

<%== $change_user_info_form %>

@@ layouts/insurgent.html.ep
<!doctype html><html>
    <head>
    <title><%= $title %> - Insurgent-Auth</title>
    <link rel="stylesheet" href="/style.css" type="text/css" media="screen, projection" title="Normal" />
    </head>
    <body>
    <div id="status">
    <ul>
% if ($self->session->{'login'}) {
    <li><b>Logged in as <%= $self->session->{'login'} %></b></li>
    <li><a href="<%= url_for('account') %>">Account</a></li>
    <li><a href="<%= url_for('logout') %>">Logout</a></li>
% } else {
    <li><b>Not logged in.</b></li>
    <li><a href="<%= url_for('login') %>/">Login</a></li>
    <li><a href="<%= url_for('register') %>">Register</a></li>
% }
    </ul>
    </div>
    <%== content %>
    </body>
</html>
