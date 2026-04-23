package com.labmanagement.common.exception;

import com.labmanagement.entity.Reservation;
import lombok.Getter;

import java.util.List;

@Getter
public class ConflictException extends RuntimeException {
    private final List<Reservation> conflicts;

    public ConflictException(String message, List<Reservation> conflicts) {
        super(message);
        this.conflicts = conflicts;
    }
}
