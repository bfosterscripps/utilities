# Author: Brandon Foster
# Date: 20150821
# Purpose:
#   test to see if selenium for python is installed

import sys

try:
    # attempt to import relevant selenium pieces
    from selenium import webdriver
    from selenium.common.exceptions import TimeoutException
    from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
    from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
except ImportError:
    # exit with status of 1 to indicate there was an import error
    sys.exit(1)
else:
    # exit with a status of 0 to indicate all is well
    sys.exit(0)
