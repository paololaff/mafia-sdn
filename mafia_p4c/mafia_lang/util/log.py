import logging

_LOG_LEVEL_STRINGS = ['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG']

def _log_level(log_level_string):
    if not log_level_string in _LOG_LEVEL_STRINGS:
        message = 'Invalid log level: {0} (Available: {1})'.format(log_level_string, _LOG_LEVEL_STRINGS)
        raise ValueError(message) #argparse.ArgumentTypeError(message)

    log_level_int = getattr(logging, log_level_string, logging.INFO)
    # check the logging log_level_choices have not changed from our expected values
    assert isinstance(log_level_int, int)
    return log_level_int
