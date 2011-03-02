package Gtk2::Ex::Builder;
use strict;
use warnings;
use Sub::Call::Tail;
use Class::Accessor qw(antlers);

extends qw(Exporter);

has '_id', is => 'rw';
has '_gobj', is => 'rw';
has '_childs', is => 'rw';

BEGIN {
    our @EXPORT__in = qw(hav meta sets gets on);
    our @EXPORT__out = qw(builder);
    our @EXPORT = (@EXPORT__in, @EXPORT__out);
    
    my $__warn = sub {
        my $syntax = shift;
        sub { warn "you cannot call '${syntax}' directly." }
    };
    
    my $__tail = sub {
        my $syntax = shift;
        sub { tail &{"$syntax"} }
    };

    no strict 'refs';
    for my $syntax (@EXPORT__in) {
        *{"$syntax"} = $__tail->($syntax);
        *{"_${syntax}"} = $__warn->($syntax);
    }

    undef &__PACKAGE__::new;
}

sub builder (&) {
    my $code = shift;
    my $self = bless {
        _id => undef,
        _gobj => undef,
        _childs => [],
    }, __PACKAGE__;

    no warnings 'redefine';
    
    local *hav = sub {
        my ($obj) = @_;
        die "Gtk2 widget or builder{} block is expected for argument of 'hav'"
            unless defined $obj;
        if ($obj->isa('Gtk2::Ex::Builder')) {
            $self->_gobj->add($obj->_gobj);
        }
        else {
            $self->_gobj->add($obj);
        }
    };
    local *meta = sub {
        my @args = @_;
        die "wrong number of arguments for 'meta'" unless @args % 2 == 0;
        while (my ($k, $v) = splice @args, 0, 2) {
            if ($k eq 'is') {
                $self->_id($v);
            }
            elsif ($k eq 'isa') {
                my $module = ( $v =~ m/^Gtk2::(.+)$/ ? $v : "Gtk2::$v" );
                $self->_gobj($module->new);
            }                
        }
    };
    local *sets = sub {
        my ($command, @para) = @_;
        my $method = "set_$command";
        die "you should 'meta isa => '*' before 'sets' to create an gtk2 object"
            unless defined $self->_gobj;
        return $self->_gobj->$method(@para);
    };
    local *gets = sub {
        my ($command) = @_;
        my $method = "get_$command";
        die "you should 'meta isa => '*' before 'gets' to create an gtk2 object"
            unless defined $self->_gobj;
        return $self->_gobj->$method();
    };
    local *on = sub {
        my ($signal, $code) = @_;
        die "you should 'meta isa => '*' before 'on' to create an gtk2 object"
            unless defined $self->_gobj;
        return $signal->_gobj->signal_connect( $signal => $code );
    };
    
    $code->();
    $self;
}

sub get_gobj {
    my ($self) = @_;
    return $self->_gobj;
}

sub set_gobj {
    my ($self, $obj) = @_;
    return $self->_gobj($obj);
}

sub set_id {
    my ($self, $id) = @_;
    die "string is expected for id" if ref($id) ne '';
    return $self->_id($id);
}

sub has_id {
    my ($self) = @_;
    return $self->get_id;
}

sub get_id {
    my ($self) = @_;
    return unless defined $self->_id;
    return $self->_id;
}

sub get_widget {
    my ($self, $find_id) = @_;

    my $id = $self->get_id;
    return $self->get_gobj if defined $id and $id eq $find_id;

    for my $widget (@{ $self->_childs }) {
        my $id = $widget->get_id;
        return $widget->get_gobj if defined $id and $id eq $find_id;
    }
}



1;
