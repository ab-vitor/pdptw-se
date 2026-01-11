import io
import contextlib
import functools
import contextvars

# Tracks how many decorated functions are currently active
active_indent_level = contextvars.ContextVar("active_indent_level", default=0)

def indent_prints(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # Capture current level before increment
        previous_level = active_indent_level.get()
        token = active_indent_level.set(previous_level + 1)

        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            try:
                result = func(*args, **kwargs)
            finally:
                active_indent_level.reset(token)

        # Use previous_level + 1: this is the level active during the function
        for line in buf.getvalue().splitlines():
            print("\t" * (previous_level + 1) + line)

        return result
    return wrapper