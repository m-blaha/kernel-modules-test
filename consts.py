# DNF5 integration-test-compatible fixture location.
import os

FIXTURES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "fixtures"))
INVALID_UTF8_CHAR = '\udcfd'
