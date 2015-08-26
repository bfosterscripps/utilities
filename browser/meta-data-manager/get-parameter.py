from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0

import argparse

parser = argparse.ArgumentParser(description='Use Selenium to open a browser to a given URL and fetch a mdManager parameter value with javascript.')

# set up expectations as to what arguments you wish to receive

parser.add_argument('-p, --parameter', dest='parameter', default='OrigPubDate',
                   help='parameter name to query from the metadata manager')

parser.add_argument('-u, --url', dest='url', default='http://www.hgtv.com',
                   help='URL to navigate to in the browser and check for the mdManager on')

parser.add_argument('-b, --browser', dest='browser', default='firefox',
                   help='which browser to open with Selenium')

parser.add_argument('-f, --file', dest='file', default='None',
                  help='a path to a file with a list of URLs')

# actually parse out the arguments you received.
args = parser.parse_args()


# Create a new instance of the Firefox driver
driver = webdriver.Firefox()

getParameterJs='return mdManager.getParameter("' + args.parameter + '");'

if args.file is None:
    # go to a provided url
    driver.get(args.url)

    # execute some javascript to get the OrigPubDate value from metadata manager
    print driver.execute_script(getParameterJs)
else:
    with open(args.file) as f:
        for line in f:
            # go to a provided url
            driver.get(line)

            # execute some javascript to get the OrigPubDate value from metadata manager
            print driver.execute_script(getParameterJs)

# quit the browser
driver.quit()
