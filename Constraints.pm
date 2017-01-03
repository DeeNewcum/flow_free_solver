package Constraints;

# Relatively straightfoward moves, that don't require any tree searching.



# returns true to indicate that some move was made, false to indicate no move was made,
#       and -1 to indicate that the board is now in an invalid state
sub check_all_constraints {
    my ($board) = @_;

    my $original_fingerprint = $board->fingerprint();
    my $moves_made = 0;

    return 0 if ($board->is_won());

    # fail if the board is in an invalid state
    return -1 if _space_unfilled($board);

    #$moves_made++ if _tails_next_to_each_other($board);

    $moves_made++ if _only_one_move_available($board);

    # have we changed the board at all?
    return $original_fingerprint ne $board->fingerprint();
}


# Sometimes a path has only one move available.  Extend the path in that direction.
sub _only_one_move_available {
    my ($board) = @_;

    my $made_move = 0;

    for my $x (0..$board->{width}-1) {
        for my $y (0..$board->{height}-1) {
            next unless $board->{is_tail}[$x][$y];

            my $open = 0;       # how many cells are open, out of the four cardinal directions
            my $last_open_dir;
            for my $direction (0..3) {
                my ($x2, $y2) = $board->mv($x, $y, $direction)
                    or next;
                if ($board->{grid}[$x2][$y2] == 0) {
                    $open++;
                    $last_open_dir = $direction;
                }
            }

            if ($open == 1) {
                # Woohoo!  We can move in that direction.
                $board->move_tail($x, $y, $last_open_dir);

                # Before we continue, figure out if the tails have met each other, otherwise
                # we end up with some weird results.
                _tails_next_to_each_other($board, $x2, $y2);

                $made_move++;
            }
        }
    }

    return $made_move;
}


# if two tails of the same pipe are immediately adjacent to each other,
# then the pipe should be completed
sub _tails_next_to_each_other {
    my ($board, $x, $y) = @_;
            # ^^ $x and $y are optional;  if they're specified, then we just scan that one cell

    if (defined($x) && defined($y)) {
        return 0 unless $board->{is_tail}[$x][$y];
        return ___tails_next_to_each_other($board, $x, $y);
    }

    my $made_move = 0;

    for $x (0..$board->{width}-1) {
        for $y (0..$board->{height}-1) {
            next unless $board->{is_tail}[$x][$y];

            $made_move++
                if ___tails_next_to_each_other($board, $x, $y);
        }
    }

    return $made_move;
}

sub ___tails_next_to_each_other {
    my ($board, $x, $y) = @_;

    for my $direction (0..3) {
        my ($x2, $y2) = $board->mv($x, $y, $direction)
            or next;
        if ($board->{grid}[$x2][$y2] == $board->{grid}[$x][$y]
                && $board->{is_tail}[$x2][$y2])
        {
            $board->move_tail($x, $y, $direction);
            return 1;
        }
    }
    return 1;
}


# If a gap has formed behind a pipe, then note that this board is in a failed state.
# (constraint -- we always fill every nook and cranny)
sub _space_unfilled {
    my ($board) = @_;
    return 0;
}

1;
