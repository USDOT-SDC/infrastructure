class Constants:

    LOGGER_NAME = "log4sdc-common"
    LOGGER_LOG_LEVEL_ENV_VAR = "LOG_LEVEL"
    LOGGER_DEFAULT_LOG_LEVEL = "WARN"

    def __setattr__(self, attr, value):
        if hasattr(self, attr):
            raise Exception("Attempting to alter read-only value")

        self.__dict__[attr] = value

