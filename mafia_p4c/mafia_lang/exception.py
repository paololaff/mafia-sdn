from .util.log import logging

class MafiaError(Exception):
    """Base class for exceptions of the MAFIA compiler.

    Attributes:
        expression -- input expression in which the error occurred
        message -- explanation of the error
    """
    def __init__(self, expression = "", message = ""):
        super(MafiaError, self).__init__()
        self.expression = expression
        self.message = message
        self.logger = logging.getLogger(__name__)

    def to_string(self):
        return "%s -> %s" % (self.expression, self.message)

    def __str__(self):
        error = self.to_string()
        self.logger.error("%s", error)
        return error

class MafiaSyntaxError(MafiaError):
    def __init__(self, expression, message):
        super(MafiaSyntaxError, self).__init__(expression, message)

class MafiaSemanticError(MafiaError):
    def __init__(self, expression, message):
        super(MafiaSemanticError, self).__init__(expression, message)

class MafiaSymbolLookupError(MafiaError):
    def __init__(self, expression, message):
        super(MafiaSymbolLookupError, self).__init__(expression, message)

# class MafiaSemanticError(MafiaError):
#     """Exception raised for semantic errors."""

#     def __init__(self, expression, message):
#         super(MafiaSemanticError, self).__init__()
#         self.expression = expression
#         self.message = message
#         self.logger = logging.getLogger(__name__)

#     def to_string(self):
#         return "%s: %s" % (self.expression, self.message)

#     def __str__(self):
#         error = self.to_string()
#         self.logger.debug("%s", error)
#         return error

# class MafiaSymbolLookupError(MafiaError):
#     """Exception raised for symbol lookup errors."""

#     def __init__(self, expression, message):
#         super(MafiaSymbolLookupError, self).__init__()
#         self.expression = expression
#         self.message = message
#         self.logger = logging.getLogger(__name__)

#     def to_string(self):
#         return "%s: %s" % (self.expression, self.message)

#     def __str__(self):
#         error = self.to_string()
#         self.logger.debug("%s", error)
#         return error

