import os
import fcntl
import pandas as pd
from enum import Enum

# The idea was to write into a CSV file without concurrence,
# but it didn't work as expected. At least, it writes the CSV correctly.

def parse_field(field: str) -> str:
    if isinstance(field, Enum):
        return field.name  # Or str(field), depending on desired output
    return field


def struct_to_key_dict(obj, exclude_fields=None) -> dict:
    """
    Extract fields from a class instance into a dictionary, skipping specified fields.
    """
    exclude_fields = exclude_fields or set()
    return {
        key: parse_field(value)
        for key, value in vars(obj).items()
        if key not in exclude_fields
    }


def write_csv_with_flock(filename: str, data: pd.DataFrame, delimiter: str = ";")->None:
    """
    Write a DataFrame to a CSV file with file locking (exclusive lock).
    """
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    file_exists = os.path.isfile(filename)

    with open(filename, "a", newline="") as f:
        fcntl.flock(f, fcntl.LOCK_EX)  # Exclusive lock

        data.to_csv(f, sep=delimiter, header=not file_exists, index=False)

        fcntl.flock(f, fcntl.LOCK_UN)  # Unlock
