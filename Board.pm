package Board;

    use strict;
    use warnings;

    use Data::Dumper;

my @directions = (
    [-1, 0],
    [0, -1],
    [1, 0],
    [0, 1],
);

sub LEFT  { 0 }
sub UP    { 1 }
sub RIGHT { 2 }
sub DOWN  { 3 }


# TODO:  Do some input validation -- make sure that each pipe has two ends.  It would be easy
#           to make a mistake and give only one end to a pipe.
sub load {
    my ($class, $filename) = @_;

    open my $fin, '<', $filename        or die "Can't open $filename: $!\n";
    my @lines = <$fin>;
    @lines = map {chomp; $_} @lines;
    @lines = grep {!/^\s*#/ && !/^\s*$/} @lines;

    my $self = {
        height => scalar(@lines),
        width => length($lines[0]),
        grid => [],
        is_tail => []
    };

    my @pipe_end_count;
    for my $y (0..$self->{height}-1) {
        my $line = $lines[$y];
        my @chars = split('', $line);
        for my $x (0..$self->{width}-1) {
            my $char = $chars[$x];
            $char =~ s/\./0/;
            $self->{grid}[$x][$y] = $char;
            if ($char > 0) {
                $self->{is_tail}[$x][$y] = 1;
                $pipe_end_count[$char]++;
            }
        }
    }

    # sanity check -- Each pipe should have two ends, no more, no less.  Three shalt thou not count, 
    # nor count thou one, excepting that thou then proceed to two.
    for my $pipe (0..$#pipe_end_count) {
        next unless defined($pipe_end_count[$pipe]);
        if ($pipe_end_count[$pipe] != 2) {
            die "Error -- Pipe #$pipe has ", $pipe_end_count[$pipe], " ends.  It should have two.\n";
        }
    }

    return bless $self, $class;
}


# Given a coordinate, move in a particular direction, and return the target coordinates.
# Returns undef if you ran off the board.
#
# This isn't a real move like move(), rather it's a trial/temporary move.
sub mv {
    my ($self, $x, $y, $direction) = @_;
    $x += $directions[$direction][0];
    $y += $directions[$direction][1];
    if ($x < $self->{width}
         && $x >= 0
         && $y < $self->{height}
         && $y >= 0)
    {
        return ($x, $y);
    } else {
        return;
    }
}


sub is_in_bounds {
    my ($self, $x, $y) = @_;
    return ($x < $self->{width}
         && $x >= 0
         && $y < $self->{height}
         && $y >= 0);
}


sub move_tail {
    my ($self, $x, $y, $direction) = @_;
    my ($target_x, $target_y) = $self->mv($x, $y, $direction)
            or return 0;
    #my $target_x = $x + $directions[$direction][0];
    #my $target_y = $y + $directions[$direction][1];
    #if ($self->is_in_bounds($target_x, $target_y)) {
        my $pipe_num = $self->{grid}[$x][$y];
        if ($self->{grid}[$target_x][$target_y]) {
            if ($self->{is_tail}[$target_x][$target_y]
                        && $self->{grid}[$target_x][$target_y] == $self->{grid}[$x][$y]) {
                # The two tails have met and joined.  Mazel tov!
                $self->{is_tail}[$x][$y] = 0;
                $self->{is_tail}[$target_x][$target_y] = 0;
                return 1;
            } else {
                # You can't run one pipe into a different pipe.
                return 0;
            }
        }
        $self->{grid}[$target_x][$target_y] = $self->{grid}[$x][$y];
        $self->{is_tail}[$x][$y] = 0;
        $self->{is_tail}[$target_x][$target_y] = 1;
        return 1;
    #} else {
        #return 0;
    #}
}



# is the board in a winning state?
sub is_won {
    my ($self) = @_;

    for my $x (0..$self->{width}-1)  {
        for my $y (0..$self->{height}-1) {
            return 0 if (!$self->{grid}[$x][$y]);
            return 0 if ($self->{is_tail}[$x][$y]);
        }
    }
    return 1;
}


sub pretty_print {
    my ($self) = @_;

    for my $y (0..$self->{height}-1) {
        for my $x (0..$self->{width}-1)  {
            my $cell = $self->{grid}[$x][$y];
            my $display = $cell;
            if ($self->{is_tail}[$x][$y]) {
                $display = 'O';
            }
            if ($cell == 0) {
                print "\e[0m\e[30;1m",  "•";
            } else {
                my $bg = "\e[48;5;${cell}m";
                my $fg = ($cell > 7) ?   "\e[30m"   : "\e[37;1m";
                print "$bg$fg$display";
            }
            #print "\e[0m";
        }
        print "\e[0m",  "\n";
    }
    print "\n";
}


# Return a single string that represents the board.  This can be used to detect if anything on the
# board changed, it's also used for unit tests.
sub fingerprint {
    my ($self) = @_;
    return join("\n", map {  join("", @$_)   } @{$self->{grid}}  );
}


1;
