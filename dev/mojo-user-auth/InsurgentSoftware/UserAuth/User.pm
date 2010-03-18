package InsurgentSoftware::UserAuth::User;

use Moose;
use InsurgentSoftware::UserAuth::UserExtraData;

use DateTime;

has fullname => (
    isa => "Str",
    is => "rw",
);

has email => (
    isa => "Str",
    is => "rw",
);

has password => (
    isa => "Str",
    is => "rw",
);

has extra_data => (
    isa => "InsurgentSoftware::UserAuth::UserExtraData",
    is => "rw",
    default => sub {
        return InsurgentSoftware::UserAuth::UserExtraData->new()
    },
);

has confirmed => (
    isa => "Bool",
    is => "rw",
    default => 0,
);

has confirm_code => (
    isa => "Str",
    is => "rw",
);

has last_confirmation_sent_at => (
    isa => "Maybe[DateTime]",
    is => "rw",
);

sub verify_password
{
    my $self = shift;
    my $pass = shift;

    return ($self->password() eq $pass);
}

1;
